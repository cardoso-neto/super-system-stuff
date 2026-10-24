#!/bin/bash
set -euo pipefail

settings="$HOME/.t3/userdata/desktop-settings.json"
mkdir -p "$(dirname "$settings")" "$HOME/.local/share/applications"
[[ -f "$settings" ]] || printf '{}\n' > "$settings"
temporary=$(mktemp "${settings}.XXXXXX")
trap 'rm -f "$temporary"' EXIT
jq '.localEnvironmentEnabled = false' "$settings" > "$temporary"
mv "$temporary" "$settings"

cat > "$HOME/.local/share/applications/t3code.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=T3 Code (Beta)
Comment=T3 Code desktop client
Exec=$HOME/Applications/T3-Code.AppImage %U
Icon=t3code
StartupWMClass=t3code
Terminal=false
Categories=Development;
MimeType=x-scheme-handler/t3code;
DESKTOP

update-desktop-database "$HOME/.local/share/applications"
