#!/bin/sh
set -eu

VID="28de"
PID="2300"
FLAG="/run/.valve-index-rebooted"

for dev in /dev/hidraw*; do
  [ -e "$dev" ] || continue
  sys="/sys/class/hidraw/$(basename "$dev")/device"

  v="$(cat "$sys/idVendor" 2>/dev/null || true)"
  p="$(cat "$sys/idProduct" 2>/dev/null || true)"
  v="${v#0x}"
  p="${p#0x}"

  if [ "$v" = "$VID" ] && [ "$p" = "$PID" ]; then
    if printf '\x16\x01' | cat - /dev/zero | head -c 64 > "$dev"; then
      : > "$FLAG"
      exit 0
    else
      echo "Failed to write reboot command to $dev" >&2
      exit 1
    fi
  fi
done

exit 0
