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
reporter="$(dirname "$0")/../../../shared/t3-findings/report.sh"
work_dir=""
current_step=""
finish() {
  local status=$?
  if [[ -n "$work_dir" ]]; then
    if [[ "$status" -ne 0 && ! -s "$work_dir/failures" ]]; then
      {
        printf 'Machine updater on %s: %s(exit %s)\n' "$(hostname)" "$current_step" "$status"
        if [[ -f "$work_dir/step" ]]; then tail -n 100 "$work_dir/step"; fi
      } >> "$work_dir/failures"
    fi
    if [[ -s "$work_dir/failures" ]]; then
      /bin/bash "$reporter" < "$work_dir/failures" || echo "Failure report remains queued for T3."
    else
      /bin/bash "$reporter" --flush || echo "Pending failure reports could not reach T3."
    fi
    rm -rf "$work_dir"
  fi
  rm -f "$state_dir/lock"
}

if ! "$dry_run"; then
  power=$(/usr/bin/pmset -g ps) || exit 1
  if [[ "$power" != *"'AC Power'"* ]]; then
    echo "Skipping updates while on battery."
    exit 0
  fi
  mkdir -p "$state_dir" || exit 1
  /usr/bin/shlock -p "$$" -f "$state_dir/lock" || exit 0
  trap finish EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  work_dir=$(mktemp -d "$state_dir/run.XXXXXX") || exit 1
fi

failures=0
record_failure() {
  local result=$1 output=$2
  shift 2
  echo "FAILED (exit $result)"
  failures=$((failures + 1))
  {
    printf 'Machine updater on %s: ' "$(hostname)"
    printf '%q ' "$@"
    printf '(exit %s)\n' "$result"
    tail -n 100 "$output"
    printf '\n'
  } >> "$work_dir/failures"
}

run() {
  local result
  printf '\n[%s]' "$(date '+%F %T %Z')"
  printf ' %q' "$@"
  printf '\n'
  if "$dry_run"; then return; fi
  printf -v current_step '%q ' "$@"
  "$@" </dev/null 2>&1 | tee "$work_dir/step"
  result=${PIPESTATUS[0]}
  if [[ "$result" -eq 0 ]]; then
    echo "OK"
  else
    record_failure "$result" "$work_dir/step" "$@"
  fi
  return "$result"
}

update_casks() {
  local outdated cask metadata result
  if "$dry_run"; then
    echo "Update all outdated casks, checking actual app versions and using native updaters for Docker and Windscribe, and relaunching T3 Code if it was running."
    return
  fi
  if outdated=$(brew outdated --cask --greedy --quiet 2> "$work_dir/casks.stderr"); then
    cat "$work_dir/casks.stderr" >&2
  else
    result=$?
    cat "$work_dir/casks.stderr" >&2
    record_failure "$result" "$work_dir/casks.stderr" brew outdated --cask --greedy --quiet
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
      t3-code) upgrade_cask_and_relaunch "$cask" com.t3tools.t3code ;;
      *) run brew upgrade --no-ask --cask --greedy --no-quit "$cask" ;;
    esac
  done <<< "$outdated"
}

# --no-quit replaces the bundle under a running app, which keeps running the old version.
upgrade_cask_and_relaunch() {
  local cask=$1 bundle_id=$2 was_running
  was_running=$(app_is_running "$bundle_id")
  run brew upgrade --no-ask --cask --greedy --no-quit "$cask" || return
  [[ "$was_running" == true ]] && run relaunch_app "$bundle_id"
}

app_is_running() {
  /usr/bin/osascript -e "application id \"$1\" is running"
}

relaunch_app() {
  local bundle_id=$1
  /usr/bin/osascript -e "quit app id \"$bundle_id\"" || return
  for _ in {1..30}; do
    [[ "$(app_is_running "$bundle_id")" == false ]] && break
    sleep 1
  done
  [[ "$(app_is_running "$bundle_id")" == false ]] || return
  /usr/bin/open -g -b "$bundle_id"
}

run brew update
run brew upgrade --no-ask --formula
run /bin/bash "$(dirname "$0")/sync-tailscale-service.sh"
update_casks
run npm update --global --allow-scripts=@googleworkspace/cli
run npm install --global --include=optional t3@latest
run t3 update --channel stable --yes --base-dir "$HOME/.t3"
if [[ -x "$HOME/.local/bin/claude" ]]; then run "$HOME/.local/bin/claude" update; fi
if [[ -x "$HOME/.grok/bin/grok" ]]; then run "$HOME/.grok/bin/grok" update --stable; fi
if [[ -x "$HOME/.local/bin/muse" ]]; then
  run env MUSE_NO_AUTO_UPDATE=0 MUSE_SYNC_UPDATE=1 MUSE_UPDATE_INTERVAL_SECONDS=0 "$HOME/.local/bin/muse" --version
fi
if [[ -x "$HOME/.bun/bin/bun" ]]; then run "$HOME/.bun/bin/bun" upgrade; fi
run uv tool upgrade --all
run brew cleanup

echo "Finished: $failures failed steps."
[[ "$failures" -eq 0 ]]
