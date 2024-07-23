#!/bin/sh

# https://geekoverdose.wordpress.com/2019/08/01/i3-window-manager-selectively-make-any-notification-urgent-urgency-flag-to-highlight-the-workspace/

wmctrl -r $1 -b add,demands_attention
