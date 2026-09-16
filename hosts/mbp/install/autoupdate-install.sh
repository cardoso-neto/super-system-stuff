#!/bin/bash
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
updater="$script_dir/../bin/autoupdate.sh"
label=dev.neurohive.machine-autoupdate
domain="gui/$(id -u)"
plist="$HOME/Library/LaunchAgents/$label.plist"
log_dir="$HOME/Library/Logs/machine-autoupdate"
mkdir -p "$HOME/Library/LaunchAgents" "$log_dir"

/usr/bin/plutil -create xml1 "$plist"
/usr/bin/plutil -insert Label -string "$label" "$plist"
/usr/bin/plutil -insert ProgramArguments -json '[]' "$plist"
/usr/bin/plutil -insert ProgramArguments.0 -string /bin/bash "$plist"
/usr/bin/plutil -insert ProgramArguments.1 -string "$updater" "$plist"
/usr/bin/plutil -insert StartCalendarInterval -json '{"Hour":3,"Minute":0}' "$plist"
/usr/bin/plutil -insert ProcessType -string Background "$plist"
/usr/bin/plutil -insert LowPriorityIO -bool YES "$plist"
/usr/bin/plutil -insert StandardOutPath -string "$log_dir/scheduler.log" "$plist"
/usr/bin/plutil -insert StandardErrorPath -string "$log_dir/scheduler.log" "$plist"
/usr/bin/plutil -lint "$plist"

if launchctl print "$domain/$label" >/dev/null 2>&1; then
  launchctl bootout "$domain/$label"
fi
launchctl bootstrap "$domain" "$plist"

old_label=com.github.domt4.homebrew-autoupdate
if launchctl print "$domain/$old_label" >/dev/null 2>&1; then
  launchctl bootout "$domain/$old_label"
fi
old_plist="$HOME/Library/LaunchAgents/$old_label.plist"
if [[ -f "$old_plist" ]]; then
  mv "$old_plist" "$log_dir/$old_label.plist.disabled"
fi
echo "Installed daily updates at 03:00 local time, on AC power. Logs: $log_dir"
