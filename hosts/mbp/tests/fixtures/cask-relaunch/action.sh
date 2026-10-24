#!/bin/bash
source "$1" --dry-run >/dev/null
work_dir=$2
upgrade_exit=$3
running=$4
relaunch_exit=$5
later_exit=$6
dry_run=false
: > "$work_dir/failures"

brew() {
  printf 'brew %s\n' "$*" >> "$work_dir/commands"
  return "$upgrade_exit"
}
app_is_running() { printf '%s\n' "$running"; }
relaunch_app() {
  printf 'relaunch_app %s\n' "$*" >> "$work_dir/commands"
  return "$relaunch_exit"
}
later_step() {
  printf 'later_step\n' >> "$work_dir/commands"
  return "$later_exit"
}

upgrade_cask_and_relaunch t3-code com.t3tools.t3code
upgrade_status=$?
run later_step
later_status=$?
printf '{"upgradeStatus":%s,"laterStatus":%s,"failures":%s}\n' \
  "$upgrade_status" "$later_status" "$failures" > "$work_dir/result.json"
[[ "$failures" -eq 0 ]]
