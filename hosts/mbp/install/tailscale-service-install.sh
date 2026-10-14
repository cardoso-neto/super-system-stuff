#!/bin/bash
set -euo pipefail

if [[ "$(id -u)" == 0 ]]; then
  echo "Run this script as the user who runs the updater, without sudo." >&2
  exit 1
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
rule=$(mktemp)
trap 'rm -f "$rule"' EXIT
printf '%s ALL=(root) NOPASSWD: /bin/launchctl kickstart -k system/sh.brew.tailscale\n' "$(id -un)" > "$rule"
/usr/bin/sudo /usr/sbin/visudo -cf "$rule"
/usr/bin/sudo /usr/bin/install -o root -g wheel -m 0440 "$rule" /etc/sudoers.d/machine-autoupdate-tailscale
/bin/bash "$script_dir/../bin/sync-tailscale-service.sh"
