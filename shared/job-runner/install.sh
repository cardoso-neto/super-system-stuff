#!/bin/bash
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
destination="$HOME/.local/bin/job-runner"
mkdir -p "$(dirname "$destination")"
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -O "$script_dir/main.swift" -o "$build_dir/job-runner"
install -m 755 "$build_dir/job-runner" "$destination.new"
mv -f "$destination.new" "$destination"
echo "Installed $destination"
