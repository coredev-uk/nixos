# quickshell-record --start MONITOR FILE | --replay MONITOR DIR SECONDS | --saved TITLE FILE | --failed TITLE REASON
# --start and --replay become gpu-screen-recorder (--start: the bar signals it by pid, SIGINT
# finishes the file; --replay: the quickshell-replay user unit, SIGUSR1 saves the buffer).
# --saved and --failed are the notifications raised once a file is written or the recorder has
# failed. gpu-screen-recorder calls back as `quickshell-record FILE replay` for each saved replay.

# The NixOS package, built to find the capability wrapper for gsr-kms-server
# (programs.gpu-screen-recorder, hosts/common/desktop/hyprland.nix). Without the wrapper it
# would ask for root through polkit on every start.
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
	# KMS capture of one monitor at 60 fps (both screens run faster; the file doesn't need it),
	# with what the default output plays. If the bar dies or restarts, SIGINT finishes the file
	# rather than leaving a recording no indicator reports (and an mp4 without its index).
	exec setpriv --pdeathsig INT "$recorder" -w "$1" -f 60 -a default_output -o "$2"
}

# The instant replay buffer (services/Replay.qml): the last SECONDS of the monitor and of what the
# default output plays, held in RAM at a constant 20 Mbit/s (SECONDS = 300 is 750 MB), written to
# DIR when the unit gets SIGUSR1. Buffering shares nothing, so it isn't on air.
replay() {
	require_recorder
	mkdir -p "$2"
	exec "$recorder" -w "$1" -f 60 -a default_output -c mp4 -bm cbr -q 20000 \
		-r "$3" -replay-storage ram -sc "$0" -o "$2"
}

# Called by gpu-screen-recorder with each saved replay: gives it the recordings' naming, then
# raises the notification from a unit of its own, since stopping the replay unit would
# otherwise take the waiting notification (and its actions) with it.
replay_saved() {
	local file=$1 name clip
	name=$(basename "$file")
	clip=$(dirname "$file")/replay-${name#Replay_}
	mv -n "$file" "$clip"
	systemd-run --user --quiet --collect "$0" --saved "Replay saved" "$clip"
}

# Clicking the notification plays the file; the button opens its folder. notify-send waits for
# the choice and prints its action, so this stays around until the notification is closed.
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
