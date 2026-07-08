#!/bin/sh

if command -v curl >/dev/null 2>&1; then
  ip_addr=$(curl -fsS --max-time 2 https://icanhazip.com 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
  ip_addr=$(wget -qO- -T 2 https://icanhazip.com 2>/dev/null)
else
  ip_addr=""
fi

if [ -z "$ip_addr" ]; then
  ip_addr="offline"
fi

printf '%s\n' "$ip_addr"
