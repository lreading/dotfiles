#!/usr/bin/env bash

report_failure() {
  local failure_file="$XDG_RUNTIME_DIR/hypr-startup-errors-$HYPRLAND_INSTANCE_SIGNATURE"
  local message

  {
    flock -x 9 || return 1
    printf '%s\n' "$1" >> "$failure_file"
    message=$(printf 'Startup failures:\n'; cat "$failure_file")
    hyprctl seterror 'rgba(ff5555ff)' "$message"
  } 9>"$failure_file.lock"
}

if [[ ${1:-} == --failure ]]; then
  report_failure "$2"
  exit
fi

label=$1
shift

printf 'START %s\n' "$label"
"$@"
status=$?
printf 'EXIT %s status=%s\n' "$label" "$status"
if (( status != 0 )); then
  report_failure "$label (status $status)"
fi
exit "$status"
