#!/bin/bash
source "$1" --dry-run >/dev/null
state_dir=$2
reporter=$3
work_dir=$(mktemp -d "$state_dir/run.XXXXXX")
trap finish EXIT
dry_run=false

run /bin/sh -c 'echo successful-step-output'
run /bin/sh -c 'echo failed-step-stdout; echo failed-step-stderr >&2; exit 23'
run /bin/sh -c 'echo later-successful-step-output'
[[ "$failures" -eq 0 ]]
