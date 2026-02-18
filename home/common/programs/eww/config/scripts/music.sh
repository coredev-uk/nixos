#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/eww/music"
CACHE_LIMIT=20
mkdir -p "$CACHE_DIR"

NATIVE_CLIENTS=(cider spotify)
URL_PATTERNS=(music.apple.com open.spotify.com)

get_player() {
	for p in "${NATIVE_CLIENTS[@]}"; do
		if playerctl --player="$p" status 2>/dev/null | grep -q "Playing\|Paused"; then
			echo "$p"
			return
		fi
	done

	while IFS= read -r p; do
		local xurl
		xurl=$(playerctl --player="$p" metadata xesam:url 2>/dev/null)
		for pattern in "${URL_PATTERNS[@]}"; do
			if [[ "$xurl" == *"$pattern"* ]]; then
				echo "$p"
				return
			fi
		done
	done < <(playerctl --list-all 2>/dev/null)

	echo ""
}

# Enforce cache limit by removing oldest files when over the cap
prune_cache() {
	local count
	count=$(find "$CACHE_DIR" -maxdepth 1 -type f | wc -l)
	if [ "$count" -gt "$CACHE_LIMIT" ]; then
		find "$CACHE_DIR" -maxdepth 1 -type f -printf '%T+ %p\n' |
			sort | head -n $((count - CACHE_LIMIT)) |
			awk '{print $2}' |
			xargs -r rm --
	fi
}

art() {
	local player
	player=$(get_player)

	if [ -z "$player" ]; then
		echo ""
		return
	fi

	local meta url id file_path
	meta=$(playerctl --player="$player" metadata 2>/dev/null)
	url=$(echo "$meta" | awk '/artUrl/{print $3}')
	id=$(echo "$meta" | awk -F'/' '/trackid/{print $NF}' | tr -d "'")

	[ -z "$url" ] && echo "" && return

	local src="$url"
	if [[ "$url" == file://* ]]; then
		src="${url#file://}"
		src=$(printf '%b' "${src//%/\\x}")
	fi

	if [ -z "$id" ]; then
		id=$(echo "$url" | md5sum | awk '{print $1}')
	fi
	file_path="${CACHE_DIR}/${id}.jpg"

	if [ ! -f "$file_path" ]; then
		ffmpeg -loglevel quiet -y -i "$src" -vf "scale=24:24" "$file_path" 2>/dev/null ||
			{
				echo ""
				return
			}
		prune_cache
	fi

	echo "$file_path"
}

title() {
	local player
	player=$(get_player)
	[ -z "$player" ] && echo "" && return
	playerctl --player="$player" metadata --format '{{title}}' 2>/dev/null
}

artist() {
	local player
	player=$(get_player)
	[ -z "$player" ] && echo "" && return
	playerctl --player="$player" metadata --format '{{artist}}' 2>/dev/null
}

status() {
	local player
	player=$(get_player)
	if [ -n "$player" ] && playerctl --player="$player" status 2>/dev/null | grep -q "^Playing$"; then
		echo "true"
	else
		echo "false"
	fi
}

case "$1" in
--art) art ;;
--title) title ;;
--artist) artist ;;
--status) status ;;
esac
