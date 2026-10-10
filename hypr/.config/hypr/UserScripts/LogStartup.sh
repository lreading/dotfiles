#!/usr/bin/env bash

label=$1
shift

printf 'START %s\n' "$label"
"$@"
status=$?
printf 'EXIT %s status=%s\n' "$label" "$status"
exit "$status"
