#!/bin/sh

ip_addr=$(
  ip route get 1.1.1.1 2>/dev/null | awk '
    {
      for (i = 1; i <= NF; i++) {
        if ($i == "src") {
          print $(i + 1)
          exit
        }
      }
    }'
)

if [ -z "$ip_addr" ]; then
  ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

if [ -z "$ip_addr" ]; then
  ip_addr=$(
    ifconfig 2>/dev/null | awk '
      $1 == "inet" && $2 != "127.0.0.1" {
        print $2
        exit
      }'
  )
fi

if [ -z "$ip_addr" ]; then
  ip_addr="offline"
fi

printf '%s\n' "$ip_addr"
