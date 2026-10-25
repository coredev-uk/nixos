#!/usr/bin/env bash
# Set brightness on all DDC/CI monitors.
# Takes an absolute percentage ("65", "65%") or a relative step ("10%+", "10%-");
# "get" prints the current percentage instead.
# The GN800 is dimmer than the GP850 at the same setting, so it is driven 1.18x higher.
# Monitors are matched by model: ddcciN follows the i2c bus number, which can change.

declare -A scale=([GN800]=118)

devices=(/sys/class/backlight/ddcci*)
[ -e "${devices[0]}" ] || exit 0

model() { cat "$1/device/idModel" 2>/dev/null; }
percent() { echo $(($(cat "$1/brightness") * 100 / $(cat "$1/max_brightness"))); }

# Read from an unscaled monitor: a scaled one sits at 100 well before the setting does.
current() {
	for dev in "${devices[@]}"; do
		if [ -z "${scale[$(model "$dev")]:-}" ]; then
			percent "$dev"
			return
		fi
	done
	percent "${devices[0]}"
}

arg="${1//%/}"
case "$arg" in
get)
	current
	exit 0
	;;
*+ | *-)
	step=${arg%?}
	if [ "${arg: -1}" = "+" ]; then target=$(($(current) + step)); else target=$(($(current) - step)); fi
	;;
*) target=$arg ;;
esac
target=$((target < 0 ? 0 : target > 100 ? 100 : target))

for dev in "${devices[@]}"; do
	value=$((target * ${scale[$(model "$dev")]:-100} / 100))
	brightnessctl -q -d "$(basename "$dev")" set "$((value > 100 ? 100 : value))%" &
done

wait
