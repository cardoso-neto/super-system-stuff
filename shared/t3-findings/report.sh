#!/usr/bin/env bash
set -euo pipefail
umask 077

if (( $# > 1 )) || { (( $# == 1 )) && [[ $1 != --flush ]]; }; then
    echo 'Usage: report.sh [--flush]' >&2
    exit 2
fi

state_dir=${T3_FINDINGS_STATE_DIR:-$HOME/.local/state/t3-findings}
config=${T3_FINDINGS_CONFIG:-$HOME/.config/t3-findings/webhook.json}
mkdir -p "$state_dir"
chmod 700 "$state_dir"

pending_file=
trap '[[ -z $pending_file ]] || rm -f "$pending_file"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if (( $# == 0 )) && [[ ! -t 0 ]]; then
    report_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    pending_file=$(mktemp "$state_dir/.pending.XXXXXX")
    jq -Rs --arg reportId "$report_id" '{reportId: $reportId, error: .}' > "$pending_file"
    if jq -e '.error != ""' "$pending_file" >/dev/null; then
        mv "$pending_file" "$state_dir/$report_id.json"
    else
        rm "$pending_file"
    fi
    pending_file=
fi

shopt -s nullglob
reports=("$state_dir"/*.json)
(( ${#reports[@]} )) || exit 0

if ! curl_config=$(jq -er '
    .url | select(type == "string")
    | select(test("^https?://[^[:space:][:cntrl:]]+$"))
    | "url = " + tojson
' "$config" 2>/dev/null); then
    echo 't3-findings: delivery pending; webhook configuration missing or invalid' >&2
    exit 1
fi

failed=0
for report in "${reports[@]}"; do
    if http_status=$(printf '%s\n' "$curl_config" | curl -q --config - \
        --silent --output /dev/null --write-out '%{http_code}' \
        --connect-timeout 5 --max-time 15 --proto '=http,https' \
        --header 'Content-Type: application/json' --data-binary "@$report" 2>/dev/null); then
        if [[ $http_status == 2[0-9][0-9] ]]; then
            rm -f "$report"
            continue
        fi
        echo "t3-findings: delivery pending (HTTP $http_status)" >&2
    else
        echo 't3-findings: delivery pending (transport failure)' >&2
    fi
    failed=1
done
exit "$failed"
