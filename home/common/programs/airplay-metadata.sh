# airplay-metadata TITLE ARTIST ALBUM ART_URL POSITION_MS LENGTH_MS
# Passes the playing track to OwnTone (airplay.nix) so AirPlay devices show it instead of the
# pipe's file name. OwnTone reads Shairport-style metadata items from "<pipe>.metadata", but only
# while it plays the pipe, so the bar calls this on every track change and every few seconds:
# the full set (with artwork) goes out when the track changed or OwnTone just started reading,
# otherwise only the progress. $fifo (the metadata pipe) is set by the Nix wrapper.

title=$1 artist=$2 album=$3 art_url=$4 position_ms=$5 length_ms=$6
state=${XDG_RUNTIME_DIR:-/tmp}/airplay-metadata.state

[[ -p $fifo ]] || exit 0
# Opening a FIFO without blocking fails when nobody reads it: OwnTone isn't playing the pipe.
if ! dd of="$fifo" oflag=nonblock count=0 status=none 2>/dev/null; then
	rm -f "$state"
	exit 0
fi

# One metadata item; OwnTone keys on the code alone.
item() {
	local code=$1 file=$2
	printf '<item><type>636f7265</type><code>%s</code><length>%d</length>\n<data encoding="base64">\n%s</data></item>\n' \
		"$code" "$(stat -c %s "$file")" "$(base64 -w0 "$file")"
}

text_item() {
	printf '%s' "$2" >"$tmp/value"
	if [[ -s $tmp/value ]]; then
		item "$1" "$tmp/value"
	fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

key=$(printf '%s\n' "$title" "$artist" "$album" "$art_url" | sha256sum | cut -c1-16)
{
	if [[ ! -f $state || $(<"$state") != "$key" ]]; then
		text_item 6d696e6d "$title"  # minm
		text_item 61736172 "$artist" # asar
		text_item 6173616c "$album"  # asal
		# Artwork: a file or a URL, at most 1 MiB (OwnTone's limit).
		case $art_url in
		file://*) cp "${art_url#file://}" "$tmp/art" 2>/dev/null || true ;;
		http://* | https://*) curl -sfL --max-time 5 --max-filesize 1048576 -o "$tmp/art" "$art_url" || true ;;
		esac
		if [[ -s $tmp/art && $(stat -c %s "$tmp/art") -le 1048576 ]]; then
			item 50494354 "$tmp/art" # PICT
		fi
	fi
	# prgr: start/position/end in 44.1 kHz samples; OwnTone needs a non-zero start.
	if ((length_ms > 0)); then
		printf '1/%d/%d' $((1 + position_ms * 441 / 10)) $((1 + length_ms * 441 / 10)) >"$tmp/progress"
		item 70726772 "$tmp/progress"
	fi
} >"$tmp/items"

# Artwork can exceed the pipe buffer, so this write may wait for OwnTone to read; never for long.
if timeout 5 cp "$tmp/items" "$fifo"; then
	printf '%s' "$key" >"$state"
fi
