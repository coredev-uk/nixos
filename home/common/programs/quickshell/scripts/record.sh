# quickshell-record --start MONITOR FILE | --replay MONITOR DIR SECONDS | --saved TITLE FILE | --failed TITLE REASON
# --start and --replay become gpu-screen-recorder (--start: the bar signals it by pid, SIGINT
# finishes the file; --replay: the quickshell-replay unit, SIGUSR1 saves the buffer). --saved and
# --failed raise notifications. gpu-screen-recorder calls back `quickshell-record FILE replay` per saved replay.

# The NixOS package is built to find the capability wrapper for gsr-kms-server
# (hosts/common/desktop/hyprland.nix); without it every start would ask for root via polkit.
recorder=/run/current-system/sw/bin/gpu-screen-recorder

require_recorder() {
	if [ ! -x "$recorder" ] || [ ! -e /run/wrappers/bin/gsr-kms-server ]; then
		echo "gsr error: the recorder's KMS wrapper is missing; rebuild NixOS first." >&2
		exit 1
	fi
}

start() {
	require_recorder
	mkdir -p "$(dirname "$2")"
	# KMS capture of one monitor at 60 fps plus default output audio. SIGINT finishes the file if
	# the bar dies, avoiding an unreported recording and an mp4 without its index.
	exec setpriv --pdeathsig INT "$recorder" -w "$1" -f 60 -a default_output -o "$2"
}

# Instant replay buffer (services/Replay.qml): last SECONDS of the monitor and default output audio,
# in RAM at 20 Mbit/s (300 s = 750 MB), written to DIR on SIGUSR1. Buffering shares nothing.
replay() {
	require_recorder
	mkdir -p "$2"
	exec "$recorder" -w "$1" -f 60 -a default_output -c mp4 -bm cbr -q 20000 \
		-r "$3" -replay-storage ram -sc "$0" -o "$2"
}

# Called by gpu-screen-recorder per saved replay: applies the recordings' naming, then notifies from
# its own unit, since stopping the replay unit would take the waiting notification with it.
replay_saved() {
	local file=$1 name clip
	name=$(basename "$file")
	clip=$(dirname "$file")/replay-${name#Replay_}
	mv -n "$file" "$clip"
	systemd-run --user --quiet --collect "$0" --saved "Replay saved" "$clip"
}

# Click plays the file, the button opens its folder. notify-send waits and prints the action, so
# this stays until the notification closes.
saved() {
	local choice
	choice=$(notify-send --app-name="Screen recorder" --icon=camera-video --wait \
		--action=default=Play --action=folder="Show in folder" \
		"$1" "$(basename "$2")") || true
	case $choice in
	default) xdg-open "$2" ;;
	folder) xdg-open "$(dirname "$2")" ;;
	esac
}

failed() {
	notify-send --app-name="Screen recorder" --icon=camera-video --urgency=critical "$1" "$2"
}

case ${1:-} in
--start) start "$2" "$3" ;;
--replay) replay "$2" "$3" "$4" ;;
--saved) saved "$2" "$3" ;;
--failed) failed "$2" "$3" ;;
/*)
	if [ "${2:-}" = replay ]; then
		replay_saved "$1"
	fi
	;;
*)
	echo "usage: quickshell-record --start MONITOR FILE | --replay MONITOR DIR SECONDS | --saved TITLE FILE | --failed TITLE REASON" >&2
	exit 2
	;;
esac
