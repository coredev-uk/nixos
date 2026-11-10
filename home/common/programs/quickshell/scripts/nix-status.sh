# Prints one JSON object describing atlas's Nix state and the home-lab binary cache, for the
# panel's Nix view (services/NixStatus.qml). Every source is optional and fetched in parallel
# with short timeouts, so off the LAN the local fields still come out and the rest is null:
#
#   system    what runs here: nixos-version, generation, reboot pending (kernel, initrd or modules
#             differ from the booted system), and whether the running system's store path is in
#             the cache (null = cache unreachable)
#   upstream  main's flake.lock on GitHub: its nixpkgs revision, and update_available when that
#             differs from the running system's
#   cache     Attic's numbers from Prometheus (nix-cache-exporter); reachable = Prometheus answered
#   build     the nix-cache-builder (polls every 30 minutes, builds new commits on main and on open
#             pull requests): its last run, and main's latest built commit (success, failing_since,
#             targets); build.* from the exporter are absent until the first run has finished
#   updates   the open lock updates: BOT Cecil's nightly pull requests, one per flake input
#             (flake-update/<input>), each merging itself once its checks pass: [{input, number,
#             url, opened_at, auto_merge, checks: [{name, state: success|failure|pending, since}],
#             failing_since}]; checks (two requests a pull request) only with gh's token, else
#             null; failing_since is since when the builder has failed it across its refreshes;
#             null when GitHub didn't answer
#   failed_units  [{scope, name, description}] from systemctl --failed, system and user
#             (scope "system" | "user"); null when neither manager answered
# Epoch seconds everywhere; sizes in bytes.

prometheus=https://prometheus.hera.ac/api/v1/query
lock_url=https://raw.githubusercontent.com/coredev-uk/nixos/main/flake.lock
cache_url=https://nix-cache.hera.ac/coredev
repo_api=https://api.github.com/repos/coredev-uk/nixos

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fetch() {
	curl --silent --location --connect-timeout 3 --max-time 8 "$@" 2>/dev/null || true
}

query() {
	fetch --get "$prometheus" --data-urlencode "query=$2" >"$tmp/$1" &
}

query metrics '{__name__=~"nix_cache_.+"}'
query active 'sum(kube_job_status_active{namespace="nix-cache"})'
query up 'up{namespace="nix-cache"}'
fetch "$lock_url" >"$tmp/lock" &

# GitHub with gh's token when it has one (5000 requests an hour; anonymous ones get 60, shared
# with everything else on the home IP).
auth=()
if command -v gh >/dev/null && token=$(timeout 3 gh auth token 2>/dev/null) && [ -n "$token" ]; then
	auth=(--header "Authorization: Bearer $token")
fi
github() {
	fetch --fail "${auth[@]}" --header "Accept: application/vnd.github+json" "$repo_api$1"
}
# The update pull requests, then each one's check runs and statuses.
: >"$tmp/updates"
updates() {
	github '/pulls?state=open&per_page=100' |
		jq -c '[.[] | select(.head.ref | startswith("flake-update/"))]' >"$tmp/updates" 2>/dev/null || return 0
	# No answer from GitHub: leave it empty, which reads as unknown below.
	[ -s "$tmp/updates" ] || return 0
	local number sha
	while read -r number sha; do
		: >"$tmp/checks-$number"
		: >"$tmp/status-$number"
		if [ "${#auth[@]}" -gt 0 ]; then
			github "/commits/$sha/check-runs?per_page=100" >"$tmp/checks-$number" &
			github "/commits/$sha/status" >"$tmp/status-$number" &
		fi
	done < <(jq -r '.[] | "\(.number) \(.head.sha)"' "$tmp/updates")
	wait
	# One array of {pr, runs, statuses} for the jq below.
	jq -c '.[]' "$tmp/updates" | while read -r pr; do
		number=$(jq -r .number <<<"$pr")
		jq -nc --argjson pr "$pr" --rawfile runs "$tmp/checks-$number" --rawfile statuses "$tmp/status-$number" \
			'{pr: $pr, runs: ($runs | fromjson? // null), statuses: ($statuses | fromjson? // null)}'
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
	--rawfile metrics "$tmp/metrics" \
	--rawfile active "$tmp/active" \
	--rawfile up "$tmp/up" \
	--rawfile updates "$tmp/updates" \
	--rawfile units_system "$tmp/system" \
	--rawfile units_user "$tmp/user" \
	'
  def prom($raw): ($raw | fromjson? // null) | if .status == "success" then .data.result else null end;
  def gauge($rs; $name): first($rs[]? | select(.metric.__name__ == $name) | .value[1] | tonumber) // null;
  def labelled($rs; $name; $labels):
    first($rs[]? | select(.metric.__name__ == $name and (.metric | contains($labels))) | .value[1] | tonumber) // null;
  def flag($v): if $v == null then null else $v == 1 end;
  def by($rs; $name; $label):
    [$rs[]? | select(.metric.__name__ == $name) | {key: .metric[$label], value: (.value[1] | tonumber)}] | from_entries;
  def byref($rs; $name; $ref):
    [$rs[]? | select(.metric.__name__ == $name and .metric.ref == $ref) | {key: .metric.target, value: (.value[1] | tonumber)}] | from_entries;
  def epoch: if . == null then null else fromdateiso8601 end;

  prom($metrics) as $m
  | prom($active) as $a
  | prom($up) as $u
  | ($lock | fromjson? // null | if . == null then null else .nodes[.nodes.root.inputs.nixpkgs].locked end) as $pin
  | byref($m; "nix_cache_build_target_success"; "main") as $target_ok
  | byref($m; "nix_cache_build_closure_bytes"; "main") as $target_bytes
  | by($m; "nix_cache_flake_input_last_modified_timestamp_seconds"; "input") as $inputs
  | ($updates | fromjson? // null) as $ups
  | {
      fetched_at: $now,
      system: {
        version: $os.nixosVersion,
        nixpkgs_rev: $os.nixpkgsRevision,
        generation: ($generation | tonumber? // null),
        generation_time: ($generation_time | tonumber? // null),
        reboot_pending: $reboot_pending,
        cached: (if $narinfo == "200" then true elif $narinfo == "404" then false else null end)
      },
      upstream: {
        reachable: ($pin != null),
        nixpkgs_rev: $pin.rev,
        nixpkgs_modified: $pin.lastModified,
        update_available: (if $pin == null or $os.nixpkgsRevision == null then null else $pin.rev != $os.nixpkgsRevision end)
      },
      cache: {
        reachable: ($m != null),
        exporter_up: (if ($u | length) == 0 then null else all($u[]; .value[1] == "1") end),
        objects: gauge($m; "nix_cache_objects"),
        nar_bytes: gauge($m; "nix_cache_nar_bytes"),
        stored_bytes: gauge($m; "nix_cache_stored_bytes"),
        accessed_24h: gauge($m; "nix_cache_objects_accessed_24h"),
        last_push: gauge($m; "nix_cache_last_push_timestamp_seconds")
      },
      build: {
        running: (if $a == null then null else (($a[0].value[1] // "0") | tonumber) > 0 end),
        success: flag(gauge($m; "nix_cache_build_success")),
        failed_phase: (first($m[]? | select(.metric.__name__ == "nix_cache_build_failed_phase" and .value[1] == "1") | .metric.phase) // null),
        last_run: gauge($m; "nix_cache_build_last_run_timestamp_seconds"),
        last_success: gauge($m; "nix_cache_build_last_success_timestamp_seconds"),
        duration: gauge($m; "nix_cache_build_duration_seconds"),
        phases: by($m; "nix_cache_build_phase_duration_seconds"; "phase"),
        main: {
          success: flag(labelled($m; "nix_cache_ref_build_success"; {ref: "main"})),
          finished: labelled($m; "nix_cache_ref_build_timestamp_seconds"; {ref: "main"}),
          failing_since: labelled($m; "nix_cache_ref_failing_since_timestamp_seconds"; {ref: "main"})
        },
        targets: ([$target_ok, $target_bytes | keys[]] | unique | map({
          name: .,
          success: flag($target_ok[.]),
          closure_bytes: $target_bytes[.]
        })),
        oldest_input: ($inputs | to_entries | if length == 0 then null else min_by(.value) | {name: .key, modified: .value} end),
        store_used_bytes: gauge($m; "nix_cache_builder_store_used_bytes"),
        store_size_bytes: gauge($m; "nix_cache_builder_store_size_bytes")
      },
      # Every check the ruleset on main requires is listed, as pending until it first reports
      # (nix-cache only does once the builder picks the commit up on its next poll).
      updates: (
        if ($ups | type) != "array" then null
        else [$ups[] | .pr as $pr | {
          input: ($pr.head.ref | ltrimstr("flake-update/")),
          number: $pr.number,
          url: $pr.html_url,
          opened_at: ($pr.created_at | epoch),
          auto_merge: ($pr.auto_merge != null),
          checks: (
            if .runs == null and .statuses == null then null
            else
              ([.runs.check_runs[]? | {
                name,
                state: (if .status != "completed" then "pending"
                        elif .conclusion == "success" or .conclusion == "neutral" or .conclusion == "skipped" then "success"
                        else "failure" end),
                since: ((if .status == "completed" then .completed_at else .started_at end) | epoch)
              }]
              + [.statuses.statuses[]? | {
                name: .context,
                state: (if .state == "success" then "success" elif .state == "pending" then "pending" else "failure" end),
                since: (.updated_at | epoch)
              }]) as $reported
              | $reported + [["evaluate", "flake-checker", "poseidon", "nix-cache"][]
                  | select(. as $n | $reported | all(.name != $n))
                  | {name: ., state: "pending", since: null}]
              | sort_by(.name)
            end
          ),
          failing_since: labelled($m; "nix_cache_ref_failing_since_timestamp_seconds"; {ref: "pr-\($pr.number)"})
        }] | sort_by(.input)
        end
      ),
      failed_units: (
        [{scope: "system", raw: $units_system}, {scope: "user", raw: $units_user}]
        | map(. as $s | ($s.raw | fromjson? // null) | if . == null then null else map({scope: $s.scope, name: .unit, description: .description}) end)
        | if all(. == null) then null else map(. // []) | add end
      )
    }
  '
