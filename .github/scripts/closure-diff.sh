#!/usr/bin/env bash
# Usage: closure-diff.sh HEAD_JSON BASE_JSON
#
# Each file is target-outputs.sh's {"<target>": "<store path>"}: the head's, and the pull request
# base's. Prints Markdown: per target how the closure's size changed and which packages changed
# version (`nix store diff-closures`, the package names and versions as Nix prints them).
#
# Nothing is built twice: both sides are realised with `nix build`, which only substitutes (the
# head was just built here or is in the cache; the base was built on main and is in the cache, or
# already in this runner's store). A side that can't be had says so instead of building it.
#
# MAX_LINES (default 120) caps the package lines of a target; FULL_OUT, when set, gets the
# uncapped Markdown (for the job summary). Plain bash 3 and jq only: it also runs on macOS.
# shellcheck disable=SC2016 # the backticks are Markdown, not command substitution
set -uo pipefail

head_json="$1"
base_json="$2"
max_lines="${MAX_LINES:-120}"

# bytes -> "1.5 GiB"; signed with delta (+/-) when $2 is "delta".
size() {
	jq -nr --argjson n "$1" --arg mode "${2:-}" '
    def fmt: . as $v | ($v | fabs) as $a
      | if $a >= 1073741824 then "\(($a / 1073741824 * 10 | round) / 10) GiB"
        elif $a >= 1048576 then "\(($a / 1048576 * 10 | round) / 10) MiB"
        elif $a >= 1024 then "\(($a / 1024 * 10 | round) / 10) KiB"
        else "\($a) B" end;
    if $mode == "delta" then (if $n < 0 then "-" else "+" end) + ($n | fmt) else $n | fmt end'
}

closure_size() { nix path-info -S "$1" 2>/dev/null | cut -f2 | head -n1; }

one() {
	local name="$1" head="$2" base="$3" err diff lines hs bs shown
	if [ -z "$base" ]; then
		printf -- '- `%s`: new target, nothing to compare with.\n' "$name"
		return
	fi
	if [ "$base" = "$head" ]; then
		printf -- '- `%s`: unchanged.\n' "$name"
		return
	fi
	err="$(nix build --no-link --max-jobs 0 "$base" "$head" 2>&1 >/dev/null)" || {
		printf -- '- `%s`: no closure diff, a side is not in the cache or this store: %s\n' "$name" "$(printf '%s' "$err" | tail -n1)"
		return
	}
	hs="$(closure_size "$head")"
	bs="$(closure_size "$base")"
	diff="$(nix store diff-closures "$base" "$head" 2>&1)"
	lines="$(printf '%s' "$diff" | grep -c . || true)"
	shown="$diff"
	if [ "$lines" -gt "$max_lines" ] && [ "${FULL:-0}" != 1 ]; then
		shown="$(printf '%s\n' "$diff" | head -n "$max_lines")
… and $((lines - max_lines)) more (the job summary has them all)"
	fi
	printf '<details><summary><code>%s</code>: closure %s → %s (%s), %s changed</summary>\n\n' "$name" \
		"$(size "$bs")" "$(size "$hs")" "$(size "$((hs - bs))" delta)" \
		"$(if [ "$lines" -eq 0 ]; then echo 'no package version'; else echo "$lines package line$([ "$lines" -eq 1 ] || echo s)"; fi)"
	if [ "$lines" -gt 0 ]; then
		printf '```text\n%s\n```\n\n' "$shown"
	else
		printf 'Same package versions; a rebuild with other inputs (configuration, patches, build flags).\n\n'
	fi
	printf '</details>\n'
}

render() {
	jq -r 'keys[]' "$head_json" | while read -r name; do
		one "$name" "$(jq -r --arg n "$name" '.[$n]' "$head_json")" "$(jq -r --arg n "$name" '.[$n] // empty' "$base_json")"
	done
}

if [ -n "${FULL_OUT:-}" ]; then
	FULL=1 render >"$FULL_OUT"
fi
render
