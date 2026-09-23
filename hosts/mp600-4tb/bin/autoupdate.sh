#!/bin/bash

printf '\n[%s] Updating Claude Code\n' "$(date --iso-8601=seconds)"
/home/nei/.local/bin/claude update
claude_status=$?

npx --yes t3@latest update --channel stable --yes
t3_status=$?

printf '[%s] Update results: Claude=%s T3=%s\n' "$(date --iso-8601=seconds)" "$claude_status" "$t3_status"
if (( claude_status != 0 || t3_status != 0 )); then
    exit 1
fi
