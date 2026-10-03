#!/bin/bash
set -u

export PATH="$HOME/.local/bin:$HOME/.grok/bin:$HOME/.bun/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1
export HOMEBREW_NO_AUTO_UPDATE=1
export NONINTERACTIVE=1

dry_run=false
case "${1:-}" in
  --dry-run) dry_run=true ;;
  '') exec "$HOME/.local/bin/job-runner" --name machine-autoupdate --timeout "${MACHINE_AUTOUPDATE_TIMEOUT:-4h}" -- /bin/bash "$0" --run ;;
  --run) ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

state_dir="$HOME/Library/Caches/machine-autoupdate"
if ! "$dry_run"; then
  power=$(/usr/bin/pmset -g ps) || exit 1
  if [[ "$power" != *"'AC Power'"* ]]; then
    echo "Skipping updates while on battery."
    exit 0
  fi
  mkdir -p "$state_dir" || exit 1
  /usr/bin/shlock -p "$$" -f "$state_dir/lock" || exit 0
  trap 'rm -f "$state_dir/lock"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
fi

failures=0
run() {
  printf '\n[%s]' "$(date '+%F %T %Z')"
  printf ' %q' "$@"
  printf '\n'
  if "$dry_run"; then return; fi
  if "$@" </dev/null; then
    echo "OK"
  else
    result=$?
    echo "FAILED (exit $result)"
    failures=$((failures + 1))
  fi
}

update_casks() {
  local outdated cask metadata
  if "$dry_run"; then
    echo "Update all outdated casks, checking actual app versions and using native updaters for Docker and Windscribe."
    return
  fi
  if ! outdated=$(brew outdated --cask --greedy --quiet); then
    echo "FAILED to list outdated casks"
    failures=$((failures + 1))
    return
  fi
  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    if metadata=$(brew info --json=v2 --cask "$cask") &&
      jq -e '.casks[0] | .auto_updates and (.bundle_version != null or .bundle_short_version != null) and (.outdated == false)' <<< "$metadata" >/dev/null; then
      echo "Already current (app version checked): $cask"
      continue
    fi
    case "$cask" in
      docker-desktop)
        run /Applications/Docker.app/Contents/Resources/bin/docker desktop start
        run /Applications/Docker.app/Contents/Resources/bin/docker desktop update --quiet
        ;;
      windscribe) run /Applications/Windscribe.app/Contents/MacOS/windscribe-cli update ;;
      *) run brew upgrade --no-ask --cask --greedy --no-quit "$cask" ;;
    esac
  done <<< "$outdated"
}

run brew update
run brew upgrade --no-ask --formula
update_casks
run npm update --global --allow-scripts=@googleworkspace/cli
run npm install --global --include=optional t3@latest
run t3 update --channel stable --yes --base-dir "$HOME/.t3"
if [[ -x "$HOME/.local/bin/claude" ]]; then run "$HOME/.local/bin/claude" update; fi
if [[ -x "$HOME/.grok/bin/grok" ]]; then run "$HOME/.grok/bin/grok" update --stable; fi
if [[ -x "$HOME/.bun/bin/bun" ]]; then run "$HOME/.bun/bin/bun" upgrade; fi
run uv tool upgrade --all
run pipx upgrade-all
run brew cleanup

echo "Finished: $failures failed steps."
[[ "$failures" -eq 0 ]]
