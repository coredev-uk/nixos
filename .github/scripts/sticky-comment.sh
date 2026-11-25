#!/usr/bin/env bash
# Usage: sticky-comment.sh PR MARKER FILE
#
# Posts FILE as a comment on pull request PR, or edits the one this workflow posted before (found
# by the hidden marker `<!-- MARKER -->`). An empty FILE posts nothing, and turns an earlier comment
# into "Nothing to report any more." Needs gh with GH_TOKEN (pull-requests: write) and
# GITHUB_REPOSITORY. GitHub caps a comment at 65536 characters: the body is cut at 60000.
set -euo pipefail

pr="$1"
marker="$2"
if [ -s "$3" ]; then
	body="$(head -c 60000 "$3")

<!-- $marker -->"
else
	body="Nothing to report any more.

<!-- $marker -->"
fi

id="$(gh api --paginate "repos/$GITHUB_REPOSITORY/issues/$pr/comments" \
	--jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | contains(\"<!-- $marker -->\"))) | .id" | sed -n 1p)"

if [ -n "$id" ]; then
	gh api -X PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$id" -f body="$body" >/dev/null
elif [ -s "$3" ]; then
	gh api -X POST "repos/$GITHUB_REPOSITORY/issues/$pr/comments" -f body="$body" >/dev/null
fi
