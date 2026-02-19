#!/usr/bin/env bash

hypr_workspaces() {
	local active
	active=$(hyprctl activeworkspace -j | jq -r '.id')
	hyprctl workspaces -j | jq -c --argjson active "$active" \
		'[.[] | select(.id != -99) | {id: .id, active: (.id == $active)}] | sort_by(.id)'
}

emit() {
	hypr_workspaces
}

emit

socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - |
	while read -r _; do emit; done
