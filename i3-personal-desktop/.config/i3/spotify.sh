#!/bin/bash

artist=$(playerctl -p spotify metadata artist)
title=$(playerctl -p spotify metadata title)

if [ -z "$artist" ] || [ -z "$title" ]; then
    echo ""
else
    echo "$artist - $title"
fi

