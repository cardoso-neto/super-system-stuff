#!/bin/bash
set -euo pipefail

[[ -f /Library/LaunchDaemons/sh.brew.tailscale.plist ]] || exit 0

client_version=$(/opt/homebrew/bin/tailscale version --json | jq -er '.long')
daemon_version() {
  /opt/homebrew/bin/tailscale status --json 2>/dev/null | jq -er '.Version'
}

if [[ "$(daemon_version)" == "$client_version" ]]; then
  echo "Tailscale client and daemon are current: $client_version"
  exit 0
fi

echo "Restarting Tailscale to load $client_version."
if ! /usr/bin/sudo -n /bin/launchctl kickstart -k system/sh.brew.tailscale; then
  echo "Cannot restart Tailscale. Run hosts/mbp/install/tailscale-service-install.sh to enable unattended restarts." >&2
  exit 1
fi

for _ in {1..15}; do
  if [[ "$(daemon_version || true)" == "$client_version" ]]; then
    echo "Tailscale client and daemon match: $client_version"
    exit 0
  fi
  sleep 2
done
echo "Tailscale daemon did not report $client_version after restart." >&2
exit 1
