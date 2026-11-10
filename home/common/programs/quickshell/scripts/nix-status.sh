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
#   build     the nightly nix-cache-builder CronJob: its last run, targets, oldest flake input;
#             build.* from the exporter are absent until the first run has finished
#
# Epoch seconds everywhere; sizes in bytes.

prometheus=https://prometheus.hera.ac/api/v1/query
lock_url=https://raw.githubusercontent.com/coredev-uk/nixos/main/flake.lock
cache_url=https://nix-cache.hera.ac/coredev

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fetch() {
  curl --silent --location --connect-timeout 3 --max-time 8 "$@" 2>/dev/null || true
}

query() {
  fetch --get "$prometheus" --data-urlencode "query=$2" >"$tmp/$1" &
}

query metrics '{__name__=~"nix_cache_.+"}'
query kube '{__name__=~"kube_cronjob_status_last_successful_time|kube_cronjob_next_schedule_time",namespace="nix-cache",cronjob="nix-cache-builder"}'
query active 'sum(kube_job_status_active{namespace="nix-cache"})'
query up 'up{namespace="nix-cache"}'
fetch "$lock_url" >"$tmp/lock" &

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
  --rawfile kube "$tmp/kube" \
  --rawfile active "$tmp/active" \
  --rawfile up "$tmp/up" \
  '
  def prom($raw): ($raw | fromjson? // null) | if .status == "success" then .data.result else null end;
  def gauge($rs; $name): first($rs[]? | select(.metric.__name__ == $name) | .value[1] | tonumber) // null;
  def flag($v): if $v == null then null else $v == 1 end;
  def by($rs; $name; $label):
    [$rs[]? | select(.metric.__name__ == $name) | {key: .metric[$label], value: (.value[1] | tonumber)}] | from_entries;

  prom($metrics) as $m
  | prom($kube) as $k
  | prom($active) as $a
  | prom($up) as $u
  | ($lock | fromjson? // null | if . == null then null else .nodes[.nodes.root.inputs.nixpkgs].locked end) as $pin
  | by($m; "nix_cache_build_target_success"; "target") as $target_ok
  | by($m; "nix_cache_build_closure_bytes"; "target") as $target_bytes
  | by($m; "nix_cache_flake_input_last_modified_timestamp_seconds"; "input") as $inputs
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
        last_success: gauge($k; "kube_cronjob_status_last_successful_time"),
        next_run: gauge($k; "kube_cronjob_next_schedule_time"),
        duration: gauge($m; "nix_cache_build_duration_seconds"),
        phases: by($m; "nix_cache_build_phase_duration_seconds"; "phase"),
        lock_changed: flag(gauge($m; "nix_cache_build_lock_changed")),
        inputs_updated: gauge($m; "nix_cache_build_inputs_updated"),
        targets: ([$target_ok, $target_bytes | keys[]] | unique | map({
          name: .,
          success: flag($target_ok[.]),
          closure_bytes: $target_bytes[.]
        })),
        oldest_input: ($inputs | to_entries | if length == 0 then null else min_by(.value) | {name: .key, modified: .value} end),
        store_used_bytes: gauge($m; "nix_cache_builder_store_used_bytes"),
        store_size_bytes: gauge($m; "nix_cache_builder_store_size_bytes")
      }
    }
  '
