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

run 'Claude Code' "$HOME/.local/bin/claude" update
run 'T3' npx --yes t3@latest update --channel stable --yes
run 'Codex' npm --prefix "$HOME/.local" install --global @openai/codex@latest
run 'Codex path' check_codex
if [[ -x "$HOME/.grok/bin/grok" ]]; then
    run 'Grok' env npm_config_allow_scripts=@xai-official/grok "$HOME/.grok/bin/grok" update --stable
else
    printf 'Grok: skipped (not installed)\n'
fi

printf '[%s] Update results: %s failed steps\n' "$(date --iso-8601=seconds)" "$failures"
(( failures == 0 ))
