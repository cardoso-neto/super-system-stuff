#!/bin/bash
# One-time root setup for the user-owned T3 Code AppImage; later updates need no sudo.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
appimage=/home/nei/Applications/T3-Code.AppImage
profile=/etc/apparmor.d/t3code-appimage

apt-get install -y libfuse2t64
cat > "$profile" <<PROFILE
abi <abi/4.0>,
include <tunables/global>

profile t3code-appimage $appimage flags=(unconfined) {
  userns,

  include if exists <local/t3code-appimage>
}
PROFILE
apparmor_parser -r "$profile"
echo "Installed libfuse2t64 and $profile."
