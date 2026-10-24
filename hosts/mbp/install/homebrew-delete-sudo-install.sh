#!/bin/bash
set -euo pipefail

if [[ "$(id -u)" == 0 ]]; then
  echo "Run this script as the user who runs the updater, without sudo." >&2
  exit 1
fi

rule=$(mktemp)
trap 'rm -f "$rule"' EXIT
printf '%s ALL=(root) NOPASSWD: SETENV: /usr/bin/xargs -0 -- /bin/rm -r -f --\n' "$(id -un)" > "$rule"
/usr/sbin/visudo -cf "$rule"

/usr/bin/osascript - "$rule" <<'APPLESCRIPT'
on run argv
  do shell script "/usr/bin/install -o root -g wheel -m 0440 " & quoted form of (item 1 of argv) & " /etc/sudoers.d/machine-autoupdate-homebrew-delete" with administrator privileges
end run
APPLESCRIPT

/usr/bin/sudo -n -E -- /usr/bin/xargs -0 -- /bin/rm -r -f -- </dev/null
echo "Enabled unattended Homebrew cask deletion for $(id -un)."
