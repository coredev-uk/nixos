#!/usr/bin/env bash
# Usage: target-outputs.sh [DIR]
#
# Prints {"<target>": "<store path>"} for the nix-fast-build targets in $TARGETS (hosts.yml's
# matrix: `flake: { atlas = flake.nixosConfigurations.atlas...; }`) of the flake checkout in DIR
# (default: the current directory). Evaluation only, nothing is built.
set -euo pipefail

dir="$(cd "${1:-.}" && pwd)"
nix eval --json --impure --expr \
	"builtins.mapAttrs (_: d: d.outPath) (($TARGETS) (builtins.getFlake \"git+file://$dir?shallow=1\"))"
