#!/bin/bash
set -u

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
failures=0

run() {
    local name=$1
    shift
    printf '\n[%s] Updating %s\n' "$(date --iso-8601=seconds)" "$name"
    if "$@"; then
        printf '%s: OK\n' "$name"
    else
        printf '%s: FAILED\n' "$name"
        failures=$((failures + 1))
    fi
}

check_codex() {
    local expected="$HOME/.local/lib/node_modules/@openai/codex/bin/codex.js"
    local actual
    actual=$(readlink -f "$HOME/.local/bin/codex") || return 1
    if [[ "$actual" != "$expected" ]]; then
        printf 'Codex resolves to %s; expected %s\n' "$actual" "$expected"
        return 1
    fi
    "$HOME/.local/bin/codex" --version
}

update_t3_desktop() {
    local appimage="$HOME/Applications/T3-Code.AppImage" url digest
    [[ -x "$appimage" ]] || { printf 'Not installed\n'; return 0; }
    read -r url digest < <(curl -fsSL https://api.github.com/repos/pingdotgg/t3code/releases/latest |
        jq -r '.assets[] | select(.name | test("^T3-Code-.*-x86_64\\.AppImage$")) | "\(.browser_download_url) \(.digest)"')
    [[ -n "${url:-}" && "${digest:-}" == sha256:* ]] || { printf 'No AppImage in the latest release\n'; return 1; }
    if [[ "sha256:$(sha256sum < "$appimage" | cut -d' ' -f1)" == "$digest" ]]; then
        printf 'Already current: %s\n' "${url##*/}"
        return 0
    fi
    curl -fsSL -o "$appimage.part" "$url" || return 1
    if [[ "sha256:$(sha256sum < "$appimage.part" | cut -d' ' -f1)" != "$digest" ]]; then
        rm -f "$appimage.part"
        printf 'Checksum mismatch for %s\n' "${url##*/}"
        return 1
    fi
    chmod 755 "$appimage.part" && mv "$appimage.part" "$appimage" || return 1
    printf 'Installed %s\n' "${url##*/}"
    relaunch_t3_desktop
}

# Electron applies updates only on restart; the running app keeps the old AppImage mounted.
relaunch_t3_desktop() {
    local pid
    pid=$(pgrep -o -f '/\.mount_T3-Cod[^/]*/t3code') || return 0
    kill -TERM "$pid"
    for _ in {1..30}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
        printf 'T3 desktop did not quit; not relaunching\n'
        return 1
    fi
    systemd-run --user --collect --quiet "$HOME/Applications/T3-Code.AppImage"
}

run 'Claude Code' "$HOME/.local/bin/claude" update
run 'T3' npx --yes t3@latest update --channel stable --yes
run 'T3 desktop' update_t3_desktop
run 'Codex' npm --prefix "$HOME/.local" install --global @openai/codex@latest
run 'Codex path' check_codex
if [[ -x "$HOME/.grok/bin/grok" ]]; then
    run 'Grok' "$HOME/.grok/bin/grok" update --stable
else
    printf 'Grok: skipped (not installed)\n'
fi

printf '[%s] Update results: %s failed steps\n' "$(date --iso-8601=seconds)" "$failures"
(( failures == 0 ))
