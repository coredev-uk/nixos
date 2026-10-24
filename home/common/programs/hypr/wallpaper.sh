# Apple Aerial wallpaper: prints the path of a still taken from a random Aerial video.
#   get-wallpaper             grab a new still (random Aerial, random moment in it)
#   get-wallpaper --existing  print the newest cached still without fetching
#
# Packaged with writeShellApplication (paper.nix), which supplies the shebang,
# `set -o errexit -o nounset`, every dependency on PATH and AERIAL_CA_FILE.
#
# Apple publishes no still images at wallpaper size, only 4K videos. ffmpeg reads the
# video's index (at the end of the file) and one keyframe by HTTP range requests, so a
# still costs a few MB of a ~500 MB video. Decoding only that keyframe (rather than every
# frame up to the exact moment) takes ~0.5 s of CPU instead of ~30 s and ~900 MB.

OUTPUT_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/wallpapers"
MANIFEST="$OUTPUT_DIR/entries.json"
MANIFEST_MAX_AGE_DAYS=7
KEEP=5

# Apple publishes one config per macOS release (resources-config-<major>-0.plist), each
# pointing at that release's manifest tarball. Start from the newest known one and probe
# upward, so a new macOS release is picked up without editing this script.
CONFIG_BASE="https://configuration.apple.com/configurations/internetservices/aerials"
CONFIG_MIN_MAJOR=27

# Bounded network calls: retry every failure (DNS, refused, timeout) while the network
# comes up at login, and never hang on a stalled connection.
CURL_RETRY=(--connect-timeout 10 --retry 6 --retry-delay 10 --retry-all-errors)
# sylvan.apple.com chains to Apple's own root CA, which isn't in the system bundle.
APPLE_TLS=(--cacert "$AERIAL_CA_FILE")
FFMPEG_TLS=(-tls_verify 1 -ca_file "$AERIAL_CA_FILE")
# Microseconds; ffmpeg otherwise waits forever on a stalled connection.
FFMPEG_TIMEOUT=(-rw_timeout 30000000)

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

# Cached stills, newest first (by mtime). current.jpg is a symlink, so -type f skips it.
list_images() {
  find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.jpg" -exec ls -t {} + 2>/dev/null
}

newest_image() {
  local newest
  newest=$(list_images | head -n 1)
  [ -n "$newest" ] || die "No cached wallpaper in $OUTPUT_DIR"
  printf '%s\n' "$newest"
}

# Keep the newest $KEEP stills; drop leftovers from interrupted runs.
cleanup() {
  find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.part*" -delete 2>/dev/null || true
  list_images | tail -n +$((KEEP + 1)) | while IFS= read -r file; do
    rm -f "$file"
  done
}

# URL of the newest release's config; stops at the first major that isn't published (404).
newest_config() {
  local major=$CONFIG_MIN_MAJOR
  while curl -fsS --connect-timeout 10 --max-time 30 -o /dev/null \
    "$CONFIG_BASE/resources-config-$((major + 1))-0.plist" 2>/dev/null; do
    major=$((major + 1))
  done
  printf '%s\n' "$CONFIG_BASE/resources-config-$major-0.plist"
}

# Refresh entries.json from Apple's current manifest tarball once it's a week old. A failed
# refresh keeps the old manifest; only a first run without one is fatal.
refresh_manifest() {
  if [ -f "$MANIFEST" ] && [ -z "$(find "$MANIFEST" -mtime +"$MANIFEST_MAX_AGE_DAYS")" ]; then
    return 0
  fi

  local plist tarball
  if plist=$(curl -fsSL "${CURL_RETRY[@]}" --max-time 30 "$(newest_config)") &&
    tarball=$(sed -n 's|.*<string>\(https://[^<]*\.tar\)</string>.*|\1|p' <<<"$plist" | head -n 1) &&
    [ -n "$tarball" ] &&
    curl -fsSL "${CURL_RETRY[@]}" "${APPLE_TLS[@]}" --max-time 120 -o "$OUTPUT_DIR/resources.tar.part" "$tarball" &&
    tar --warning=no-unknown-keyword -xOf "$OUTPUT_DIR/resources.tar.part" entries.json >"$MANIFEST.part" &&
    jq -e '.assets | length > 0' "$MANIFEST.part" >/dev/null; then
    mv "$MANIFEST.part" "$MANIFEST"
  else
    printf 'WARNING: could not refresh the Aerial manifest\n' >&2
  fi
  rm -f "$OUTPUT_DIR/resources.tar.part" "$MANIFEST.part"
  [ -f "$MANIFEST" ] || die "No Aerial manifest"
}

fetch() {
  refresh_manifest

  # Random pick among the Aerials Apple itself shuffles (which leaves out the abstract
  # "Dynamic" ones and their portrait variants), skipping the one on screen now.
  local current_shot pick shot url duration offset path
  current_shot=$(basename "$(readlink -f "$OUTPUT_DIR/current.jpg" 2>/dev/null || true)")
  current_shot=${current_shot%%@*}
  pick=$(jq -r --arg skip "$current_shot" '
    .assets[]
    | select(.includeInShuffle and .["url-4K-SDR-240FPS"] != null and .shotID != $skip)
    | "\(.shotID)\t\(.["url-4K-SDR-240FPS"])"' "$MANIFEST" | shuf -n 1)
  [ -n "$pick" ] || die "No usable Aerial in the manifest"
  shot=${pick%%$'\t'*}
  url=${pick#*$'\t'}

  # A random moment away from the fades at either end.
  duration=$(ffprobe -v error "${FFMPEG_TLS[@]}" "${FFMPEG_TIMEOUT[@]}" \
    -show_entries format=duration -of csv=p=0 "$url") || die "Failed to read $shot"
  offset=$(awk -v d="$duration" -v r="$RANDOM" 'BEGIN { printf "%d", d * (0.1 + 0.8 * r / 32767) }')

  # shotID@offset: the next pick can tell which Aerial is on screen.
  path="$OUTPUT_DIR/$shot@$offset.jpg"
  ffmpeg -v error "${FFMPEG_TLS[@]}" "${FFMPEG_TIMEOUT[@]}" -skip_frame nokey -ss "$offset" -i "$url" \
    -frames:v 1 -q:v 2 -y "$path.part.jpg" </dev/null || {
    rm -f "$path.part.jpg"
    die "Failed to grab a frame from $shot"
  }
  mv "$path.part.jpg" "$path"

  # Only after a successful grab, so a failed fetch never deletes stills.
  cleanup
  printf '%s\n' "$path"
}

mkdir -p "$OUTPUT_DIR"
case "${1-}" in
"") fetch ;;
--existing) newest_image ;;
*) die "Usage: get-wallpaper [--existing]" ;;
esac
