#!/usr/bin/env bash
# Set brightness on all ddcci backlight devices
# Mirrors the set-brightness-all pattern from hypridle config
VAL="${1}%"

for dev in /sys/class/backlight/ddcci*; do
	[ -e "$dev" ] || continue
	brightnessctl -d "$(basename "$dev")" set "$VAL" &
done

wait
