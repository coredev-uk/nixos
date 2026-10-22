# Bing wallpaper downloader: prints the path of the downloaded image.
#   get-wallpaper             fetch a new image (random pick from Bing's daily set)
#   get-wallpaper --existing  print the newest cached image without fetching
#
# Packaged with writeShellApplication (paper.nix), which supplies the shebang,
# `set -o errexit -o nounset` and every dependency on PATH.

OUTPUT_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/bing-wallpapers"
API_URL="https://fd.api.iris.microsoft.com/v4/api/selection?placement=88000820&bcnt=1&country=UK&locale=en-GB&fmt=json"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
KEEP=3

# Bounded network calls: retry every failure (DNS, refused, timeout) while the network
# comes up at login, and never hang on a stalled connection.
CURL_RETRY=(--connect-timeout 10 --retry 6 --retry-delay 10 --retry-all-errors)

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

# Cached images, newest first (by mtime).
list_images() {
  find "$OUTPUT_DIR" -maxdepth 1 -type f \
    \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
    -exec ls -t {} + 2>/dev/null
}

newest_image() {
  local newest
  newest=$(list_images | head -n 1)
  [ -n "$newest" ] || die "No cached wallpaper in $OUTPUT_DIR"
  printf '%s\n' "$newest"
}

# Keep the newest $KEEP images; drop leftovers from interrupted downloads.
cleanup() {
  find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.part" -delete 2>/dev/null || true
  list_images | tail -n +$((KEEP + 1)) | while IFS= read -r file; do
    rm -f "$file"
  done
}

fetch() {
  local response url path
  response=$(curl -fsSL "${CURL_RETRY[@]}" --max-time 30 -A "$USER_AGENT" "$API_URL") ||
    die "Failed to fetch data from API"
  url=$(jq -r '.batchrsp.items[0].item | fromjson | .ad.landscapeImage.asset' <<<"$response") ||
    die "Failed to parse JSON response"
  [ -n "$url" ] && [ "$url" != "null" ] || die "No image URL in API response"

  path="$OUTPUT_DIR/$(basename "${url%%[?#]*}")"
  if [ -f "$path" ]; then
    # Re-picked image: bump its mtime so it counts as the newest for --existing and cleanup.
    touch "$path"
  else
    # Download under a temporary name and rename on success, so an interrupted transfer
    # never leaves a truncated image behind.
    curl -fsSL "${CURL_RETRY[@]}" --max-time 120 -o "$path.part" "$url" || {
      rm -f "$path.part"
      die "Failed to download image"
    }
    mv "$path.part" "$path"
  fi

  # Only after a successful download, so a failed fetch never deletes images.
  cleanup
  printf '%s\n' "$path"
}

mkdir -p "$OUTPUT_DIR"
case "${1-}" in
"") fetch ;;
--existing) newest_image ;;
*) die "Usage: get-wallpaper [--existing]" ;;
esac
