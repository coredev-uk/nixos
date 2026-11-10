# Print key (home/common/desktop/hyprland/config/keybindings.nix) and the screenshot popup
# (config/modules/ScreenshotPopup.qml). The wrapper in default.nix sets QS_SCREENSHOTS.
#
#   quickshell-screenshot             select an area; it goes to the clipboard and the popup
#   quickshell-screenshot save FILE   copy a capture into the screenshots directory, timestamped
#   quickshell-screenshot edit FILE   annotate in satty, then remove the capture
#   quickshell-screenshot discard FILE
#
# Captures live in $XDG_RUNTIME_DIR (tmpfs, owner only) until the popup is dismissed. They can be
# private, so the subcommands only touch files in that directory.
dir="$XDG_RUNTIME_DIR/quickshell-screenshot"
screenshots="${QS_SCREENSHOTS:?}"

# The popup hands paths back over IPC, which any of the user's processes can reach.
own() {
  case "$1" in
    *..*) return 1 ;;
    "$dir"/*.png) return 0 ;;
    *) return 1 ;;
  esac
}

case "${1:-capture}" in
  capture)
    umask 077
    mkdir -p "$dir"
    # The previous popup leaves before the selection starts, so it is not in the picture; the
    # sweep is for captures nobody can dismiss any more (the bar restarted).
    quickshell ipc -c bar call screenshot dismiss >/dev/null 2>&1 || true
    rm -f "$dir"/*.png

    file="$dir/$(date +%s%N).png"
    # Clipboard and file in one capture. No selection exits 1: nothing left to show.
    if ! grimblast copysave area "$file" >/dev/null; then
      rm -f "$file"
      exit 1
    fi
    quickshell ipc -c bar call screenshot taken "$file" >/dev/null || rm -f "$file"
    ;;

  save)
    own "${2:?no file}"
    mkdir -p "$screenshots"
    dest="$screenshots/$(date +%Y%m%d_%H%M%S).png"
    cp --no-clobber "$2" "$dest"
    printf '%s\n' "$dest"
    ;;

  edit)
    own "${2:?no file}"
    trap 'rm -f "$2"' EXIT
    mkdir -p "$screenshots"
    # Copy and save from satty; --early-exit closes it after either.
    satty --fullscreen --early-exit -f "$2" \
      --copy-command "wl-copy --type image/png" \
      --output-filename "$screenshots/%Y%m%d_%H%M%S.png"
    ;;

  discard)
    own "${2:?no file}"
    rm -f "$2"
    ;;

  *)
    echo "usage: quickshell-screenshot [save|edit|discard FILE]" >&2
    exit 2
    ;;
esac
