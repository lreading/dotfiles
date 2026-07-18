#!/usr/bin/env bash
# Full rainbow border. Hyprland animates it via the borderangle animation.
colors='"0xffff0000","0xffff8000","0xffffff00","0xff80ff00","0xff00ff00","0xff00ff80","0xff00ffff","0xff0080ff","0xff0000ff","0xff8000ff",'

hyprctl eval "hl.config({ general = { col = { active_border = { colors = { ${colors} }, angle = 270 } } } })"
