#!/bin/bash
set -u

export PATH="$HOME/.local/bin:$HOME/.grok/bin:$HOME/.bun/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1
export HOMEBREW_NO_AUTO_UPDATE=1
export NONINTERACTIVE=1

dry_run=false
case "${1:-}" in
  --dry-run) dry_run=true ;;
  '') ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

state_dir="$HOME/Library/Logs/machine-autoupdate"
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
  if [[ -f "$state_dir/latest.log" ]]; then
    mv -f "$state_dir/latest.log" "$state_dir/previous.log"
  fi
  exec > "$state_dir/latest.log" 2>&1
  : > "$state_dir/manual-updates.log"
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
  local outdated cask
  if "$dry_run"; then
    echo "Update outdated casks; report apps needing administrator access or a manual installer."
    return
  fi
  if ! outdated=$(brew outdated --cask --greedy --quiet); then
    echo "FAILED to list outdated casks"
    failures=$((failures + 1))
    return
  fi
  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    case "$cask" in
      # These installations need sudo, have root-owned app conflicts, or use a manual installer.
      basictex|claude|docker-desktop|miniconda|obs|spotify|steam|tunnelblick|windscribe)
        echo "Manual update required: $cask" | tee -a "$state_dir/manual-updates.log"
        ;;
      *) run brew upgrade --no-ask --cask --greedy --no-quit "$cask" ;;
    esac
  done <<< "$outdated"
}

run brew update
run brew upgrade --no-ask --formula
update_casks
run npm update --global --allow-scripts=@googleworkspace/cli,@xai-official/grok
run npx --yes t3@latest update --channel stable --yes --base-dir "$HOME/.t3"
if [[ -x "$HOME/.local/bin/claude" ]]; then run "$HOME/.local/bin/claude" update; fi
if [[ -x "$HOME/.grok/bin/grok" ]]; then run env npm_config_allow_scripts=@xai-official/grok "$HOME/.grok/bin/grok" update --stable; fi
if [[ -x "$HOME/.bun/bin/bun" ]]; then run "$HOME/.bun/bin/bun" upgrade; fi
run uv tool upgrade --all
run pipx upgrade-all
run brew cleanup

echo "Finished: $failures failed steps."
if ! "$dry_run" && [[ -s "$state_dir/manual-updates.log" ]]; then
  echo "Manual updates remain; see $state_dir/manual-updates.log"
fi
[[ "$failures" -eq 0 ]]
