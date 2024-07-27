#!/bin/bash

# Get the current song and artist from Spotify
song=$(playerctl metadata --format "{{ title }} - {{ artist }}")

# Set the maximum length of the display
max_length=30

# Calculate the length of the song string
length=${#song}

# Check if the song string is longer than the maximum length
if [ $length -gt $max_length ]; then
  # Calculate the position to start scrolling from
  scroll_position=$(( $(date +%s) % $length ))
  # Scroll the song string
  song="${song:scroll_position} ${song:0:scroll_position}"
  song="${song:0:$max_length}..."
else
  # If the song string is short enough, display it as is
  song="$song"
fi

echo "$song"

