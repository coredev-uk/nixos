# upgrade-report EVENT: what changed since the last report, and what to do about it (reboot,
# re-login), as a notification and as $XDG_STATE_HOME/upgrade-report/last.json, which the
# control panel's Nix view shows (quickshell services/NixStatus.qml). EVENT is
# home-success/home-failure (home-manager-auto-upgrade) or system-<SERVICE_RESULT>
# (nixos-upgrade.service, through upgrade-report@.service).
#
# last.json: {"time": epoch of the last changes, "checked": epoch of the last report,
#   "failure": {"scope", "result", "time"} | null, "actions": [string],
#   "scopes": [{"name": "system"|"home", "count", "installed": [name],
#               "packages": [{"kind": "U|D|C|A|R", "name", "from", "to", "installed"}]}]}

# The jq and awk programs are single-quoted on purpose.
# shellcheck disable=SC2016
event=${1:?usage: upgrade-report EVENT}
state="${XDG_STATE_HOME:-$HOME/.local/state}/upgrade-report"
mkdir -p "$state"
json="$state/last.json"
now=$(date +%s)

notify() {
	# No notification daemon (athena's WSL): last.json is still written.
	notify-send --app-name=Nix "$@" || true
}

# update FILTER [ARGS…]: apply a jq filter to last.json (an empty object when missing).
update() {
	local tmp
	tmp=$(mktemp "$state/.last.XXXXXX")
	{ cat "$json" 2>/dev/null || echo '{}'; } | jq "$@" >"$tmp"
	mv "$tmp" "$json"
}

fail() {
	update --arg scope "$1" --arg result "$2" --argjson now "$now" \
		'.failure = {scope: $scope, result: $result, time: $now} | .checked = $now'
	notify --urgency=critical "${1^} upgrade failed" "Details in the control panel's Nix view."
	exit 0
}

case $event in
home-success | system-success) ;;
home-failure) fail home failed ;;
system-*) fail system "${event#system-}" ;;
*)
	echo "unknown event: $event" >&2
	exit 2
	;;
esac

scopes=()
summary=()
actions=()

# check LABEL PROFILE PACKAGES: diff the profile against the generation last reported, then
# remember the new one as a GC root so the next diff still has it. PACKAGES is the profile's
# subpath of directly installed packages (sw, home-path).
check() {
	local label=$1 packages=$3 new old diff installed count shown n hypr f
	new=$(readlink -f "$2" 2>/dev/null) || return 0
	[ -e "$new" ] || return 0
	old=$(readlink "$state/$label" 2>/dev/null || true)
	nix-store --add-root "$state/$label" --realise "$new" >/dev/null
	[ -n "$old" ] && [ "$old" != "$new" ] || return 0
	diff=$(nvd diff "$old" "$new" 2>/dev/null) || return 0

	# nvd marks the root's direct dependencies [U*]: of $packages, that's what you installed.
	installed=$(nvd diff "$old/$packages" "$new/$packages" 2>/dev/null |
		awk '/^\[[UDCAR]\*\]/ { print $3 }' | jq -R . | jq -s .)
	# "[U.]  #01  name  old -> new"; added and removed packages have one version list. A list
	# ("1.2, 1.2-man x2") is cut to its first version; versionless entries ("<none>") are dropped.
	scopes+=("$(awk -F '  +' '/^\[[UDCAR][.*]\]/ {
			kind = substr($1, 2, 1); from = $4; to = ""
			if (kind == "A") { from = ""; to = $4 }
			else if (split($4, v, " -> ") == 2) { from = v[1]; to = v[2] }
			sub(/,.*/, "", from); sub(/,.*/, "", to)
			if (from ~ /^<none>/) from = ""
			if (to ~ /^<none>/) to = ""
			if (from == "" && to == "" && kind != "A" && kind != "R") next
			print kind "\t" $3 "\t" from "\t" to
		}' <<<"$diff" |
		jq -R -s --arg name "$label" --argjson installed "$installed" '
			[split("\n")[] | select(. != "") | split("\t")
			 | {kind: .[0], name: .[1], from: .[2], to: .[3]}
			 | .installed = (.name as $n | $installed | index($n) != null)]
			| {name: $name, count: length, installed: $installed,
			   packages: (sort_by(.installed | not))}')")

	count=$(jq '.count' <<<"${scopes[-1]}")
	[ "$count" -gt 0 ] || return 0
	shown=$(jq -r '.installed[:4] | join(", ")' <<<"${scopes[-1]}")
	n=$(jq '.installed | length' <<<"${scopes[-1]}")
	[ "$n" -le 4 ] || shown+=" +$((n - 4))"
	summary+=("${label^}: $count changed${shown:+ ($shown)}")

	if [ "$label" = system ]; then
		for f in kernel initrd kernel-modules; do
			if [ -e "/run/booted-system/$f" ] &&
				[ "$(readlink -f "/run/booted-system/$f")" != "$(readlink -f "$new/$f")" ]; then
				actions+=("Reboot: kernel or drivers changed")
				break
			fi
		done
		hypr=$(awk '$3 == "hyprland" { $1 = $2 = $3 = ""; sub(/^ +/, ""); print }' <<<"$diff")
		[ -z "$hypr" ] || actions+=("Log out and in: Hyprland $hypr")
	fi
}

check system /run/current-system sw
check home "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager" home-path

if [ "${#summary[@]}" -eq 0 ]; then
	update --argjson now "$now" '.checked = $now | .failure = null'
	[ "$event" != home-success ] || notify --urgency=low "Nix upgrade done" "Nothing changed."
	exit 0
fi

# The system and home upgrades report separately, half an hour apart: a scope reported in the last
# 12 h stays beside the new ones.
update --argjson now "$now" \
	--argjson scopes "$(printf '%s\n' "${scopes[@]}" | jq -s 'map(select(.count > 0))')" \
	--argjson actions "$(printf '%s\n' "${actions[@]}" | jq -R . | jq -s 'map(select(. != ""))')" \
	'(if $now - (.time // 0) < 43200 then . else {} end) as $recent
	| ($scopes | map(.name)) as $names
	| {time: $now, checked: $now, failure: null,
	   scopes: ([$recent.scopes // [] | .[] | select(.name as $n | $names | index($n) | not)] + $scopes
	            | sort_by(.name != "system")),
	   actions: ($recent.actions // [] | map(select(. as $a | $actions | index($a) | not))) + $actions}'

urgency=low
[ "${#actions[@]}" -eq 0 ] || urgency=normal
notify --urgency="$urgency" "Nix upgrade done" \
	"$(printf '%s\n' "${summary[@]}" "${actions[@]}")
Details in the control panel's Nix view."
