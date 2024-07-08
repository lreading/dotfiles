#!/bin/bash

# Get the current volume of the 'sink' (output device)
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)

# Get the mute status of the 'sink'
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no')

if [ "$mute" = "yes" ]; then
    echo "MUTED"
else
    echo "$volume"
fi

