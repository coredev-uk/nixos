#!/usr/bin/env bash
# Usage: overlay-expiry.sh [BASE_DIR]
#
# Run from a flake checkout (the PR head). Prints Markdown listing the overlays whose removal
# condition (overlays/expiry.nix) is true, nothing when none is. With BASE_DIR (a checkout of the
# PR base) they split into "Newly droppable" (true at head, not at base: this PR caused it) and
# "Still droppable". `manual` conditions can't be checked and are never listed.
# Diagnostics go to stderr.
set -euo pipefail

base_dir="${1:-}"

# Prints {"<overlay>": "<reason>"} for the expired overlays of the flake checkout in $1. The
# checkout's own lock decides which nixpkgs versions are compared. A checkout without
# overlays/expiry.nix (a base from before it existed) has none.
# shellcheck disable=SC2016 # `${...}` below is Nix, not shell.
expired_in() {
	OVERLAY_EXPIRY_DIR="$(realpath "$1")" nix eval --json --impure --expr '
    let
      dir = builtins.getEnv "OVERLAY_EXPIRY_DIR";
      file = dir + "/overlays/expiry.nix";
      inputs = (builtins.getFlake ("path:" + dir)).inputs;
      status = (import file { inherit inputs; }).status;
    in
    if builtins.pathExists file then
      builtins.mapAttrs (_: s: s.reason) (
        builtins.removeAttrs status (
          builtins.filter (n: !status.${n}.expired) (builtins.attrNames status)
        )
      )
    else
      { }
  '
}

# Bullets for the {"name": "reason"} object on stdin.
bullets() {
	jq -r 'to_entries[] | "- `\(.key)`: \(.value). Remove `\(.key)` from overlays/default.nix and its entry from overlays/expiry.nix."'
}

head_json="$(expired_in .)"

if [[ -z "$base_dir" ]]; then
	if [[ "$head_json" != "{}" ]]; then
		printf '#### Droppable overlays\n\n'
		bullets <<<"$head_json"
	fi
	exit 0
fi

if ! base_json="$(expired_in "$base_dir")"; then
	echo "overlay-expiry: could not evaluate base, treating every expired overlay as new" >&2
	base_json='{}'
fi

newly="$(jq -n --argjson h "$head_json" --argjson b "$base_json" \
	'$h | with_entries(select(.key | in($b) | not))')"
still="$(jq -n --argjson h "$head_json" --argjson b "$base_json" \
	'$h | with_entries(select(.key | in($b)))')"

if [[ "$newly" != "{}" ]]; then
	printf '#### Newly droppable\n\n'
	bullets <<<"$newly"
fi
if [[ "$still" != "{}" ]]; then
	[[ "$newly" == "{}" ]] || printf '\n'
	printf '#### Still droppable\n\n'
	bullets <<<"$still"
fi
