#!/bin/bash
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
updater="$script_dir/../bin/autoupdate.sh"
timeout="${1:-4h}"
runner="$HOME/.local/bin/job-runner"
bash "$script_dir/../../../shared/job-runner/install.sh"
"$runner" --name machine-autoupdate-install-check --timeout "$timeout" -- /usr/bin/true
label=local.nei.machine-autoupdate
domain="gui/$(id -u)"
plist="$HOME/Library/LaunchAgents/$label.plist"
log_dir="$HOME/Library/Logs/machine-autoupdate"
mkdir -p "$HOME/Library/LaunchAgents" "$log_dir"

/usr/bin/plutil -create xml1 "$plist"
/usr/bin/plutil -insert Label -string "$label" "$plist"
/usr/bin/plutil -insert ProgramArguments -json '[]' "$plist"
/usr/bin/plutil -insert ProgramArguments.0 -string "$runner" "$plist"
/usr/bin/plutil -insert ProgramArguments.1 -string --name "$plist"
/usr/bin/plutil -insert ProgramArguments.2 -string machine-autoupdate "$plist"
/usr/bin/plutil -insert ProgramArguments.3 -string --timeout "$plist"
/usr/bin/plutil -insert ProgramArguments.4 -string "$timeout" "$plist"
/usr/bin/plutil -insert ProgramArguments.5 -string -- "$plist"
/usr/bin/plutil -insert ProgramArguments.6 -string /bin/bash "$plist"
/usr/bin/plutil -insert ProgramArguments.7 -string "$updater" "$plist"
/usr/bin/plutil -insert ProgramArguments.8 -string --run "$plist"
/usr/bin/plutil -insert StartCalendarInterval -json '{"Hour":3,"Minute":0}' "$plist"
/usr/bin/plutil -insert ProcessType -string Background "$plist"
/usr/bin/plutil -insert LowPriorityIO -bool YES "$plist"
/usr/bin/plutil -insert StandardOutPath -string /dev/null "$plist"
/usr/bin/plutil -insert StandardErrorPath -string /dev/null "$plist"
/usr/bin/plutil -insert ExitTimeOut -integer 10 "$plist"
/usr/bin/plutil -lint "$plist"

if launchctl print "$domain/$label" >/dev/null 2>&1; then
  launchctl bootout "$domain/$label"
fi
launchctl bootstrap "$domain" "$plist"

for old_label in dev.neurohive.machine-autoupdate com.github.domt4.homebrew-autoupdate; do
  if launchctl print "$domain/$old_label" >/dev/null 2>&1; then
    launchctl bootout "$domain/$old_label"
  fi
  old_plist="$HOME/Library/LaunchAgents/$old_label.plist"
  if [[ -f "$old_plist" ]]; then
    mv "$old_plist" "$log_dir/$old_label.plist.disabled"
  fi
done
echo "Installed daily updates at 03:00 local time, on AC power; timeout: $timeout. Logs: Unified Logging, subsystem local.nei.jobs."
