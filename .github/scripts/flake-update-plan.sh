#!/usr/bin/env bash
# Usage: flake-update-plan.sh
#
# Run at the repository root, with Nix, jq and gh, GH_TOKEN (bot-cecil's) and GITHUB_REPOSITORY.
# Works out which flake inputs have an update and writes the matrix `["input", ...]` of those to
# refresh this run to $GITHUB_OUTPUT. Never commits anything.
#
# - An input with no update any more (merged, or moved back) has its open `flake-update/<input>`
#   pull request closed and its branch deleted.
# - At most MAX_OPEN (8) update pull requests are open at once, so the single nixos-runner is not
#   queued for hours. Inputs that already have one come first, then nixpkgs and unstable, then the
#   rest by name; the others wait for a slot on a later night.
set -euo pipefail

max_open="${MAX_OPEN:-8}"
prefix="flake-update/"

old="$(mktemp)"
cp flake.lock "$old"
nix flake update

# Root inputs whose locked content moved. Node names are renumbered between locks (nixpkgs_3), so
# each side is read through its own root; an input that only follows another is a list: skipped.
changed="$(jq -c --slurpfile old "$old" '
  .nodes as $n | $old[0] as $o
  | [.nodes.root.inputs | to_entries[] | select(.value | type == "string")
    | . as $e | ($o.nodes.root.inputs[$e.key] // null) as $was
    | select($was == null or ($was | type) != "string"
        or $o.nodes[$was].locked.narHash != $n[$e.value].locked.narHash)
    | .key]' flake.lock)"
git checkout -- flake.lock
echo "Inputs with updates: $(jq -r 'join(" ") | if . == "" then "none" else . end' <<<"$changed")"

open="$(gh pr list --repo "$GITHUB_REPOSITORY" --state open --limit 100 --json number,headRefName \
	--jq "[.[] | select(.headRefName | startswith(\"$prefix\")) | {number, input: (.headRefName | ltrimstr(\"$prefix\"))}]")"

# Updates that are gone: close them and delete their branches.
while read -r number input; do
	echo "Closing #$number: $input has no update any more"
	gh pr close "$number" --repo "$GITHUB_REPOSITORY" --delete-branch \
		--comment "Nothing to update in \`$input\` any more: the lock already has its newest commit."
done < <(jq -r --argjson changed "$changed" '.[] | select(.input as $i | $changed | index($i) | not) | "\(.number) \(.input)"' <<<"$open")

matrix="$(jq -c --argjson changed "$changed" --argjson max "$max_open" '
  [.[] | .input | select(. as $i | $changed | index($i))] as $have
  | ($changed - $have | sort_by(if . == "nixpkgs" or . == "unstable" then "0" + . else "1" + . end)) as $new
  | $have + $new[: ([$max - ($have | length), 0] | max)]' <<<"$open")"
echo "Refreshing: $(jq -r 'join(" ") | if . == "" then "none" else . end' <<<"$matrix")"
echo "matrix=$matrix" >>"$GITHUB_OUTPUT"
