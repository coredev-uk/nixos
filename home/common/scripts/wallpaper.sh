#!/bin/sh
# Bing Wallpaper Downloader - POSIX compliant
# Downloads Bing wallpaper and outputs the file path

set -e # Exit on error
set -u # Exit on undefined variable

# Configuration variables with defaults
COUNTRY="${COUNTRY:-UK}"
LOCALE="${LOCALE:-en-GB}"
ORIENTATION="${ORIENTATION:-landscape}"
OUTPUT_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/bing-wallpapers"
DEBUG="${DEBUG:-false}"
RETURN_EXISTING="${RETURN_EXISTING:-false}"

# API configuration
API_BASE="https://fd.api.iris.microsoft.com/v4/api/selection"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"

# Function to display help message
show_help() {
  cat <<EOF
Usage: ${0##*/} [options]

Download Bing wallpaper and output the file path.

Options:
    --country <code>        Country code (default: UK)
    --locale <code>         Locale code (default: en-GB)
    --orientation <type>    'landscape' or 'portrait' (default: landscape)
    --existing              Return path to most recent wallpaper without fetching
    --debug                 Enable debug logging to stderr
    --help                  Show this help message

Output:
    The script outputs the absolute path to the wallpaper file on stdout.
    Debug messages (if enabled) are sent to stderr.
    Downloaded wallpaper is stored at: ~/.cache/bing-wallpapers/

Notes:
    - Keeps maximum of 3 most recent wallpapers
    - Removes older wallpapers automatically
    - API returns random image from daily set, not a fixed daily image

Exit Codes:
    0 - Success
    1 - Error (download failed, dependencies missing, etc.)

EOF
  exit 0
}

# Function to log messages (to stderr)
log() {
  if [ "$DEBUG" = "true" ]; then
    printf '%s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
  fi
}

# Function to check required commands
check_dependencies() {
  for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'ERROR: Required command "%s" not found\n' "$cmd" >&2
      printf 'Please install: %s\n' "$cmd" >&2
      exit 1
    fi
  done
}

# Parse command-line arguments
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --country=*)
      COUNTRY="${1#*=}"
      ;;
    --locale=*)
      LOCALE="${1#*=}"
      ;;
    --orientation=*)
      ORIENTATION="${1#*=}"
      ;;
    --existing)
      RETURN_EXISTING="true"
      ;;
    --debug)
      DEBUG="true"
      ;;
    --help | -h)
      show_help
      ;;
    *)
      printf 'ERROR: Unknown option: %s\n' "$1" >&2
      show_help
      ;;
    esac
    shift
  done
}

# Validate orientation
validate_orientation() {
  case "$ORIENTATION" in
  landscape | portrait)
    return 0
    ;;
  *)
    printf 'ERROR: Invalid orientation "%s". Use "landscape" or "portrait".\n' "$ORIENTATION" >&2
    exit 1
    ;;
  esac
}

# Get most recently created wallpaper from output directory
get_existing_wallpaper() {
  _existing=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
    -exec ls -t {} + 2>/dev/null | head -n 1)

  if [ -z "$_existing" ]; then
    printf 'ERROR: No existing wallpaper found in %s\n' "$OUTPUT_DIR" >&2
    exit 1
  fi

  printf '%s\n' "$_existing"
}

# Clean up old wallpapers (keep 3 most recent, remove rest)
cleanup_old_wallpapers() {
  # Get all wallpaper files sorted by modification time (newest first)
  _all_files=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
    -exec ls -t {} + 2>/dev/null)

  if [ -z "$_all_files" ]; then
    return 0
  fi

  # Count total files
  _total=$(printf '%s\n' "$_all_files" | wc -l)

  # If we have 3 or fewer files, nothing to clean up
  if [ "$_total" -le 3 ]; then
    return 0
  fi

  # Remove everything beyond the 3 most recent
  printf '%s\n' "$_all_files" | tail -n +4 | while IFS= read -r file; do
    log "Removing old wallpaper: $file"
    rm -f "$file"
  done
}

# Fetch image URL from API
fetch_image_url() {
  _api_url="${API_BASE}?placement=88000820&bcnt=1&country=${COUNTRY}&locale=${LOCALE}&fmt=json"

  log "Fetching image data from Bing API..."
  _response=$(curl -fsSL -A "$USER_AGENT" "$_api_url") || {
    printf 'ERROR: Failed to fetch data from API\n' >&2
    exit 1
  }

  # Determine which image field to extract
  if [ "$ORIENTATION" = "landscape" ]; then
    _image_field=".ad.landscapeImage.asset"
  else
    _image_field=".ad.portraitImage.asset"
  fi

  # Extract image URL
  IMAGE_URL=$(printf '%s' "$_response" |
    jq -r ".batchrsp.items[0].item | fromjson | ${_image_field}") || {
    printf 'ERROR: Failed to parse JSON response\n' >&2
    exit 1
  }

  if [ -z "$IMAGE_URL" ] || [ "$IMAGE_URL" = "null" ]; then
    printf 'ERROR: Failed to retrieve image URL from response\n' >&2
    exit 1
  fi

  log "Image URL: $IMAGE_URL"
}

# Download the image
download_image() {
  _filename=$(basename "$IMAGE_URL" | sed 's/[?#].*//') # Remove query parameters
  OUTPUT_PATH="${OUTPUT_DIR}/${_filename}"

  # Check if file already exists
  if [ -f "$OUTPUT_PATH" ]; then
    log "Wallpaper already exists: $OUTPUT_PATH"
    return 0
  fi

  log "Downloading image to: $OUTPUT_PATH"
  curl -fsSL -o "$OUTPUT_PATH" "$IMAGE_URL" || {
    printf 'ERROR: Failed to download image\n' >&2
    exit 1
  }

  log "Download successful"
}

# Main execution
main() {
  parse_args "$@"

  # Create output directory
  mkdir -p "$OUTPUT_DIR"

  # If --existing flag is set, return most recent wallpaper without fetching
  if [ "$RETURN_EXISTING" = "true" ]; then
    get_existing_wallpaper
    exit 0
  fi

  check_dependencies
  validate_orientation

  # Clean up old wallpapers before downloading new one
  cleanup_old_wallpapers

  # Download new wallpaper
  fetch_image_url
  download_image

  log "Complete!"

  # Output the path to stdout
  printf '%s\n' "$OUTPUT_PATH"
}

# Run main function
main "$@"
