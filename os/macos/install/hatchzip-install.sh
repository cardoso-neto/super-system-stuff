#!/bin/bash
set -euo pipefail

case "$(uname -m)" in
    arm64) arch=aarch64 ;;
    x86_64) arch=x86_64 ;;
    *) echo 'Unsupported HatchZip architecture' >&2; exit 1 ;;
esac
if [[ $(sysctl -n hw.optional.arm64 2>/dev/null || true) == 1 ]]; then
    arch=aarch64
fi

download_dir=$(mktemp -d)
mounted=false
cleanup() {
    if [[ $mounted == true ]]; then
        hdiutil detach "$download_dir/mount" -quiet || return
    fi
    rm -rf "$download_dir"
}
trap cleanup EXIT

asset="HatchZip-$arch.dmg"
release_url=https://github.com/xevrion/hatchzip/releases/latest/download
curl -fL "$release_url/$asset" -o "$download_dir/$asset"
curl -fL "$release_url/$asset.sha256" -o "$download_dir/$asset.sha256"
(cd "$download_dir" && shasum -a 256 -c "$asset.sha256")
mkdir "$download_dir/mount"
hdiutil attach "$download_dir/$asset" -nobrowse -readonly -mountpoint "$download_dir/mount" -quiet
mounted=true
codesign --verify --strict "$download_dir/mount/HatchZip.app"
ditto "$download_dir/mount/HatchZip.app" /Applications/HatchZip.app

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1"
ln -sf /Applications/HatchZip.app/Contents/MacOS/hatchzip "$HOME/.local/bin/hatchzip"
ln -sf hatchzip "$HOME/.local/bin/hz"
ln -sf /Applications/HatchZip.app/Contents/Resources/man/man1/hatchzip.1 "$HOME/.local/share/man/man1/hatchzip.1"
ln -sf hatchzip.1 "$HOME/.local/share/man/man1/hz.1"
"$HOME/.local/bin/hatchzip" --version
