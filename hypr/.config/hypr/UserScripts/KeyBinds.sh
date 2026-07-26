#!/usr/bin/env bash
# Searchable live keybind list. The upstream parser reads legacy/Lua source
# files and can report stale binds; `hyprctl binds` is the authoritative table.
set -euo pipefail

if pidof yad >/dev/null 2>&1; then pkill yad || true; fi
if pidof rofi >/dev/null 2>&1; then pkill rofi || true; fi

rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-keybinds.rasi"

modifiers_from_mask() {
  local mask="$1"
  local result=""
  (( mask / 64 % 2 )) && result+="SUPER+"
  (( mask / 32 % 2 )) && result+="MOD3+"
  (( mask / 16 % 2 )) && result+="MOD2+"
  (( mask / 8 % 2 )) && result+="ALT+"
  (( mask / 4 % 2 )) && result+="CTRL+"
  (( mask / 2 % 2 )) && result+="CAPS+"
  (( mask % 2 )) && result+="SHIFT+"
  printf '%s' "${result%+}"
}

live_binds="$(hyprctl binds 2>/dev/null | awk '
  function reset() {
    mask=""; key=""; description=""; dispatcher=""; arg=""
  }
  function emit() {
    if (key == "") return
    mods=""
    n=mask+0
    if (int(n/64)%2) mods=mods "SUPER+"
    if (int(n/32)%2) mods=mods "MOD3+"
    if (int(n/16)%2) mods=mods "MOD2+"
    if (int(n/8)%2) mods=mods "ALT+"
    if (int(n/4)%2) mods=mods "CTRL+"
    if (int(n/2)%2) mods=mods "CAPS+"
    if (n%2) mods=mods "SHIFT+"
    sub(/\+$/, "", mods)
    if (mods != "") mods=mods "+"
    if (description == "") description="(unlabeled live bind; dispatcher " dispatcher ")"
    printf "%s%s — %s\n", mods, key, description
  }
  /^bind[a-z]*$/ { emit(); reset(); next }
  /^\tmodmask:/ { sub(/^\tmodmask: /, ""); mask=$0; next }
  /^\tkey:/ { sub(/^\tkey: /, ""); key=$0; next }
  /^\tdescription:/ { sub(/^\tdescription: /, ""); description=$0; next }
  /^\tdispatcher:/ { sub(/^\tdispatcher: /, ""); dispatcher=$0; next }
  /^\targ:/ { sub(/^\targ: /, ""); arg=$0; next }
  END { emit() }
')"

printf '%s\n' "$live_binds" | rofi -dmenu -i -config "$rofi_theme" \
  -mesg 'Live Hyprland binds; duplicate bindings are shown intentionally.'
