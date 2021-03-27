#!/bin/bash

set -eu

snap set system refresh.retain=2 

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done

rm /var/lib/snapd/cache/*
