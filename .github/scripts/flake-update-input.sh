#!/usr/bin/env bash
# Usage: flake-update-input.sh INPUT
#
# Run at the repository root, with Nix, jq and gh, GH_TOKEN (bot-cecil's), GITHUB_REPOSITORY and
# GITHUB_OUTPUT. Updates one root input of flake.lock in the work tree and writes what the pull
# request is made of: `skip` (true: leave the pull request as it is), `title` and `body-path`.
#
# The pull request is written the way Renovate writes one, because Clarence (home-ops
# policy-nixos.json) rules on it as it does on Renovate's: the update table (a digest, the commits
# shortened), Renovate's `<!-- rebase-check -->` box (Clarence ticks it to ask for a rebase), and
# the `stop-updating` label Clarence sets while the input waits out its release age. `<!-- inputs:
# x -->` is read by the panel's Nix view.
set -euo pipefail

input="$1"
branch="flake-update/$input"
pinned_label="stop-updating"

old="$(mktemp)"
cp flake.lock "$old"
nix flake update "$input"
if cmp -s "$old" flake.lock; then
	echo "$input is up to date"
	echo "skip=true" >>"$GITHUB_OUTPUT"
	exit 0
fi

# The locked input of root input $k in a lock (its node name is not its input name).
# shellcheck disable=SC2016 # a jq program, not shell
locked='.nodes[.nodes.root.inputs[$k]].locked'
from="$(jq -c --arg k "$input" "$locked" "$old")"
to="$(jq -c --arg k "$input" "$locked" flake.lock)"
short() { jq -r '(.rev // .narHash) | .[0:12]' <<<"$1"; }
rev() { jq -r '.rev // .narHash' <<<"$1"; }

# Leave an open pull request alone while it still says what this run would: same commit of the
# input and no conflict, or the input waiting out its release age (stop-updating), and nobody
# asked for a rebase. Otherwise (a newer commit, a conflict, a ticked box) it is made again from
# main.
pr="$(gh pr list --repo "$GITHUB_REPOSITORY" --head "$branch" --state open --json number,mergeable,labels,body --jq '.[0] // empty')"
if [ -n "$pr" ]; then
	conflicting="$(jq -r '.mergeable == "CONFLICTING"' <<<"$pr")"
	ticked="$(jq -r '.body | test("- \\[x\\]\\s*<!-- rebase-check -->"; "i")' <<<"$pr")"
	pinned="$(jq -r --arg l "$pinned_label" '[.labels[].name] | index($l) != null' <<<"$pr")"
	at_pr="$(gh api "repos/$GITHUB_REPOSITORY/contents/flake.lock?ref=$branch" --jq .content | base64 -d |
		jq -c --arg k "$input" "$locked")"
	if [ "$conflicting" = false ] && [ "$ticked" = false ] &&
		{ [ "$pinned" = true ] || [ "$(rev "$at_pr")" = "$(rev "$to")" ]; }; then
		echo "#$(jq -r .number <<<"$pr") already holds $input at $(short "$at_pr") (pinned: $pinned); leaving it"
		echo "skip=true" >>"$GITHUB_OUTPUT"
		exit 0
	fi
fi

# "[name](https://github.com/owner/repo)" for a GitHub input, else the bare name.
repo="$(jq -r 'if .type == "github" then "\(.owner)/\(.repo)" else empty end' <<<"$to")"
package="$input"
[ -z "$repo" ] || package="[$input](https://github.com/$repo)"

body="$RUNNER_TEMP/body.md"
{
	echo "This PR contains the following updates:"
	echo
	echo "| Package | Type | Update | Change |"
	echo "|---|---|---|---|"
	echo "| $package | flake input | digest | \`$(short "$from")\` → \`$(short "$to")\` |"
	echo
	if [ -n "$repo" ] && [ "$(jq -r .rev <<<"$from")" != null ]; then
		echo "[Commits](https://github.com/$repo/compare/$(rev "$from")...$(rev "$to")) between the two."
		echo
	fi
	echo "Only \`$input\` moves; every other input stays as it is, so a failure here blocks nothing else. Clarence merges it once its checks pass and the locked commit has aged (policy-nixos.json); the Hosts workflow comments with what changes in each host's closure."
	echo
	echo "---"
	echo
	echo " - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check this box"
	echo
	echo "<!-- inputs: $input -->"
} >"$body"

{
	echo "skip=false"
	echo "title=chore(flake): update $input"
	echo "body-path=$body"
} >>"$GITHUB_OUTPUT"
