#!/usr/bin/env bash
# Set matched hardware values directly using explicit device indexing

# Extract a clean, raw integer (e.g. 65)
RAW_VAL=$(echo "$1" | tr -d '%')

for dev in /sys/class/backlight/ddcci*; do
	[ -e "$dev" ] || continue
	DEV_NAME=$(basename "$dev")

	if [ "$DEV_NAME" = "ddcci6" ]; then
		# Explicitly scale up the secondary lower-nit monitor by 1.18x
		FINAL_VAL=$((RAW_VAL * 118 / 100))

		# Prevent integer overflow past 100
		if [ "$FINAL_VAL" -gt 100 ]; then
			FINAL_VAL=100
		fi
	else
		# Primary monitor (ddcci5) gets the exact requested integer
		FINAL_VAL="$RAW_VAL"
	fi

	# Pass the raw integer value directly without the % sign
	brightnessctl -d "$DEV_NAME" set "$FINAL_VAL" &
done

wait
