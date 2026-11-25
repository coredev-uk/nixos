#!/usr/bin/env bash
# Usage: poseidon-changed.sh BASE_DIR
#
# Prints "changed" or "unchanged": whether poseidon's system derivation in this checkout (the head)
# differs from the one in the checkout in BASE_DIR. Evaluation only; Linux can do it (poseidon has
# no import-from-derivation). Anything that can't be evaluated, or a missing base, counts as
# changed: building is the safe answer.
set -uo pipefail

attr='darwinConfigurations.poseidon.system.drvPath'
head="$(nix eval --raw ".#$attr" 2>/dev/null)" || {
	echo changed
	exit 0
}
[ -d "${1:-}" ] || {
	echo changed
	exit 0
}
base="$(nix eval --raw "git+file://$(cd "$1" && pwd)?shallow=1#$attr" 2>/dev/null)" || {
	echo changed
	exit 0
}
if [ "$head" = "$base" ]; then echo unchanged; else echo changed; fi
