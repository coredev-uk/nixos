# Prints one JSON object describing atlas's Nix state and the home-lab binary cache, for the
# panel's Nix view (services/NixStatus.qml). Every source is optional and fetched in parallel
# with short timeouts, so off the LAN the local fields still come out and the rest is null:
#
#   system    what runs here: nixos-version, generation, reboot pending (kernel, initrd or modules
#             differ from the booted system), and whether the running system's store path is in
#             the cache (null = cache unreachable), and matches_main: whether it is the store path
#             CI recorded for main, the nix-cache/atlas commit status of the newest main commit
#             whose Hosts run succeeded (null = unknown: unreachable, or main hasn't built yet)
#   upstream  main's flake.lock on GitHub: its nixpkgs revision, and update_available when that
#             differs from the running system's
#   cache     the Attic cache's numbers from Prometheus (attic-postgres's exporter): objects and
#             logical_bytes (uncompressed); reachable = Prometheus had them
#   build     the Hosts workflow's runs on main (.github/workflows/hosts.yml, one matrix job per
#             host, atlas and poseidon; a run fails when either host does; on every pull request and
#             every push to main), from GitHub's API: reachable = it answered, running = the latest run
#             hasn't completed, main: {success (the latest completed run's, cancelled ones skipped;
#             null if none), finished (its end), failing_since (start of the oldest run in the
#             unbroken streak of failed ones up to it; null when it succeeded), url}
#   updates   the open lock update from BOT Cecil: the nightly pull request that bumps every flake
#             input at once (flake-update), merging itself once its checks pass: [{inputs (from
#             its body's marker), number, url, opened_at, auto_merge, checks: [{name, state:
#             success|failure|pending, since}]}], empty when none is open; checks (a request: the
#             check runs, evaluate, flake-checker, poseidon and atlas required) only with gh's
#             token, else null; null when GitHub didn't answer
#   failed_units  [{scope, name, description}] from systemctl --failed, system and user
#             (scope "system" | "user"); null when neither manager answered
# Epoch seconds everywhere; sizes in bytes.

lock_url=https://raw.githubusercontent.com/coredev-uk/nixos/main/flake.lock
cache_url=https://attic.hera.ac/coredev
prometheus=https://prometheus.hera.ac/api/v1/query
repo_api=https://api.github.com/repos/coredev-uk/nixos

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fetch() {
	curl --silent --location --connect-timeout 3 --max-time 8 "$@" 2>/dev/null || true
}

fetch "$lock_url" >"$tmp/lock" &
fetch --get "$prometheus" --data-urlencode 'query={__name__=~"cnpg_nix_cache_objects|cnpg_nix_cache_nar_bytes",cache="coredev"}' >"$tmp/stats" &

# GitHub with gh's token when it has one (5000 requests an hour; anonymous ones get 60, shared
# with everything else on the home IP).
auth=()
if command -v gh >/dev/null && token=$(timeout 3 gh auth token 2>/dev/null) && [ -n "$token" ]; then
	auth=(--header "Authorization: Bearer $token")
fi
github() {
	fetch --fail "${auth[@]}" --header "Accept: application/vnd.github+json" "$repo_api$1"
}
# The Hosts workflow's latest runs on main (pushes only, newest first), then what the newest
# successful one recorded as atlas's store path.
: >"$tmp/runs"
: >"$tmp/pin"
runs() {
	github "/actions/workflows/hosts.yml/runs?branch=main&event=push&per_page=20" >"$tmp/runs"
	local sha
	sha=$(jq -r '[.workflow_runs[]? | select(.status == "completed" and .conclusion == "success")][0].head_sha // empty' "$tmp/runs" 2>/dev/null)
	[ -n "$sha" ] || return 0
	github "/commits/$sha/statuses?per_page=100" |
		jq -r 'first(.[] | select(.context == "nix-cache/atlas") | .description) // empty' >"$tmp/pin" 2>/dev/null || true
}
runs &
# The update pull request (BOT Cecil's, from this repository), then its check runs.
: >"$tmp/updates"
updates() {
	github '/pulls?state=open&per_page=100' |
		jq -c '[.[] | select(.user.login == "bot-cecil[bot]" and .head.repo.full_name == .base.repo.full_name
			and .head.ref == "flake-update")]' >"$tmp/updates" 2>/dev/null || return 0
	# No answer from GitHub: leave it empty, which reads as unknown below.
	[ -s "$tmp/updates" ] || return 0
	local number sha
	while read -r number sha; do
		: >"$tmp/checks-$number"
		if [ "${#auth[@]}" -gt 0 ]; then
			github "/commits/$sha/check-runs?per_page=100" >"$tmp/checks-$number" &
		fi
	done < <(jq -r '.[] | "\(.number) \(.head.sha)"' "$tmp/updates")
	wait
	# One array of {pr, runs} for the jq below.
	jq -c '.[]' "$tmp/updates" | while read -r pr; do
		number=$(jq -r .number <<<"$pr")
		jq -nc --argjson pr "$pr" --rawfile runs "$tmp/checks-$number" \
			'{pr: $pr, runs: ($runs | fromjson? // null)}'
	done | jq -sc . >"$tmp/updates.full"
	mv "$tmp/updates.full" "$tmp/updates"
}
updates &

# Failed units, both managers; an empty file (no bus, timeout) reads as "unknown" below.
failed() {
	timeout 5 /run/current-system/sw/bin/systemctl "${@:2}" --failed --output=json --no-legend >"$tmp/$1" 2>/dev/null || true
}
failed system &
failed user --user &

# The running system's store hash is the narinfo's name; 200 = cached, 404 = not.
current=$(readlink -f /run/current-system)
hash=${current#/nix/store/}
hash=${hash%%-*}
fetch --output /dev/null --write-out '%{http_code}' "$cache_url/$hash.narinfo" >"$tmp/narinfo" &

os=$(/run/current-system/sw/bin/nixos-version --json 2>/dev/null || echo '{}')

generation=$(readlink /nix/var/nix/profiles/system || true)
generation=${generation#system-}
generation=${generation%-link}
generation_time=
if [ -n "$generation" ]; then
	generation_time=$(stat --format %Y "/nix/var/nix/profiles/system-$generation-link" || true)
fi

# A new generation switched in is not a reboot; a different kernel, initrd or module tree is.
reboot_pending=false
if [ -e /run/booted-system ]; then
	for part in kernel initrd kernel-modules; do
		if [ "$(readlink -f "/run/booted-system/$part")" != "$(readlink -f "/run/current-system/$part")" ]; then
			reboot_pending=true
		fi
	done
fi

wait

jq -n \
	--argjson now "$(date +%s)" \
	--argjson os "$os" \
	--arg generation "$generation" \
	--arg generation_time "$generation_time" \
	--argjson reboot_pending "$reboot_pending" \
	--arg narinfo "$(cat "$tmp/narinfo")" \
	--rawfile lock "$tmp/lock" \
	--arg current "$current" \
	--rawfile pin_main "$tmp/pin" \
	--rawfile stats "$tmp/stats" \
	--rawfile runs "$tmp/runs" \
	--rawfile updates "$tmp/updates" \
	--rawfile units_system "$tmp/system" \
	--rawfile units_user "$tmp/user" \
	'
  def epoch: if . == null then null else fromdateiso8601 end;

  ($lock | fromjson? // null | if . == null then null else .nodes[.nodes.root.inputs.nixpkgs].locked end) as $pin
  | ($pin_main | gsub("^\\s+|\\s+$"; "")) as $main_path
  | ($stats | fromjson? // null | if type == "object" and .status == "success" then .data.result else null end) as $prom
  | {
      objects: (first($prom[]? | select(.metric.__name__ == "cnpg_nix_cache_objects") | .value[1] | tonumber) // null),
      logical_bytes: (first($prom[]? | select(.metric.__name__ == "cnpg_nix_cache_nar_bytes") | .value[1] | tonumber) // null)
    } as $st
  | ($runs | fromjson? // null | if type == "object" and (.workflow_runs | type) == "array" then .workflow_runs else null end) as $wr
  # Completed runs, newest first; a cancelled one (superseded) says nothing about main.
  | ([$wr[]? | select(.status == "completed" and (.conclusion == "cancelled" or .conclusion == "skipped" | not))]) as $done
  | ($done | map(.conclusion == "success") | index(true)) as $good
  | ($updates | fromjson? // null) as $ups
  | {
      fetched_at: $now,
      system: {
        version: $os.nixosVersion,
        nixpkgs_rev: $os.nixpkgsRevision,
        generation: ($generation | tonumber? // null),
        generation_time: ($generation_time | tonumber? // null),
        reboot_pending: $reboot_pending,
        cached: (if $narinfo == "200" then true elif $narinfo == "404" then false else null end),
        matches_main: (if $main_path == "" or $current == "" then null else $current == $main_path end)
      },
      upstream: {
        reachable: ($pin != null),
        nixpkgs_rev: $pin.rev,
        nixpkgs_modified: $pin.lastModified,
        update_available: (if $pin == null or $os.nixpkgsRevision == null then null else $pin.rev != $os.nixpkgsRevision end)
      },
      cache: {
        reachable: ($st.objects != null),
        objects: $st.objects,
        logical_bytes: $st.logical_bytes
      },
      build: {
        reachable: ($wr != null),
        running: (if $wr == null then null else ($wr[0].status // "completed") != "completed" end),
        main: {
          success: (if ($done | length) == 0 then null else $done[0].conclusion == "success" end),
          finished: ($done[0].updated_at | epoch),
          failing_since: (if ($done | length) == 0 or $good == 0 then null else ($done | if $good == null then . else .[:$good] end | last.created_at | epoch) end),
          url: $done[0].html_url
        }
      },
      # Every check the ruleset on main requires is listed, as pending until it first reports
      # (atlas and poseidon only do once the Hosts workflow starts on the commit); a re-run check counts by its
      # latest run.
      updates: (
        if ($ups | type) != "array" then null
        else
          [$ups[] | .pr as $pr | {
          inputs: ([($pr.body // "") | capture("<!-- inputs: (?<i>[^>]*) -->").i | splits(" +") | select(. != "")]),
          number: $pr.number,
          url: $pr.html_url,
          opened_at: ($pr.created_at | epoch),
          auto_merge: ($pr.auto_merge != null),
          checks: (
            if .runs == null then null
            else
              ([.runs.check_runs[]? | {
                name,
                state: (if .status != "completed" then "pending"
                        elif .conclusion == "success" or .conclusion == "neutral" or .conclusion == "skipped" then "success"
                        else "failure" end),
                since: ((if .status == "completed" then .completed_at else .started_at end) | epoch)
              }]
              | group_by(.name) | map(max_by(.since // 0))) as $reported
              | $reported + [["evaluate", "flake-checker", "poseidon", "atlas"][]
                  | select(. as $n | $reported | all(.name != $n))
                  | {name: ., state: "pending", since: null}]
              | sort_by(.name)
            end
          )
        }]
        end
      ),
      failed_units: (
        [{scope: "system", raw: $units_system}, {scope: "user", raw: $units_user}]
        | map(. as $s | ($s.raw | fromjson? // null) | if . == null then null else map({scope: $s.scope, name: .unit, description: .description}) end)
        | if all(. == null) then null else map(. // []) | add end
      )
    }
  '
