#!/bin/bash

# Get total and available memory
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

# Calculate used memory
mem_used=$((mem_total - mem_available))

# Calculate percentage of used memory
mem_percentage=$((mem_used * 100 / mem_total))

# Output the percentage
echo "$mem_percentage%"

