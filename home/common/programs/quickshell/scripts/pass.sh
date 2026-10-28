# quickshell-pass status|login|logout|list|details SHARE ITEM|copy SHARE ITEM FIELD
# Proton Pass for the quick-access window (modules/PassQuickAccess.qml): JSON on stdout, one
# error line on stderr and a non-zero exit on failure. Secrets only ever go to the clipboard.

# pass-cli's default Linux key store is the kernel keyring, which is denied here and gone after a
# reboot; gnome-keyring keeps the session. Set here as well because the quickshell service can
# start before the session variables are in place.
export PROTON_PASS_LINUX_KEYRING=dbus
# Updates come with the Nix package.
export PROTON_PASS_NO_UPDATE_CHECK=1

# Seconds a copied secret stays on the clipboard; overridable for testing.
clear_after=${QUICKSHELL_PASS_CLEAR_AFTER:-45}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# pass-cli's local store isn't safe to share with a pending web login: any other command run
# meanwhile finds the half-made session, deletes it, and the login then fails with "Error
# persisting session store: No such file or directory". Login holds this lock exclusively;
# the rest share it and refuse to run during a login. Long-lived children (wl-copy, the
# clipboard timer) close it so they don't block the next login.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/quickshell-pass.lock"
lock() {
	if [[ $1 == exclusive ]]; then
		flock -x -w 10 9 || {
			echo "Proton Pass is busy, try again" >&2
			exit 1
		}
	else
		flock -s -n 9 || {
			echo "Finish signing in to Proton Pass in your browser first" >&2
			exit 1
		}
	fi
}

# pass-cli logs tracing lines and anyhow chains ("Error: …", "Caused by:", indented causes) to
# stderr; boil them down to one readable line.
report_error() {
	local line message="" cause="" fallback=""
	while IFS= read -r line; do
		case $line in
		"Session is locked"*)
			message=$line
			cause=""
			break
			;;
		"Error: "*) message=${line#Error: } ;;
		"" | "Caused by:" | [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*) ;;
		[[:space:]]*)
			if [[ -n $message ]]; then
				cause=${line#"${line%%[![:space:]]*}"}
				cause=${cause#[0-9]: }
			fi
			;;
		*) fallback=$line ;;
		esac
	done <"$tmp/errors"
	message=${message:-${fallback:-pass-cli failed}}
	printf '%s\n' "$message${cause:+: $cause}" >&2
}

cli() {
	local status=0
	pass-cli "$@" 2>"$tmp/errors" || status=$?
	if ((status != 0)); then
		report_error
	fi
	return "$status"
}

status() {
	local info
	if info=$(pass-cli info --output json 2>"$tmp/errors"); then
		jq -c '{signedIn: true, account: (.email // .personal_access_token_name // "")}' <<<"$info"
	elif [[ $(<"$tmp/errors") == *"requires an authenticated client"* ]]; then
		jq -nc '{signedIn: false}'
	else
		report_error
		return 1
	fi
}

# Web login: prints {"url": …} as soon as pass-cli has the sign-in page, then {"signedIn": true}
# once the browser side is done. SIGTERM cancels the pending login.
login() {
	local line pid status=0
	mkfifo "$tmp/out"
	pass-cli login >"$tmp/out" 2>"$tmp/errors" &
	pid=$!
	trap 'kill "$pid" 2>/dev/null' TERM
	while IFS= read -r line; do
		if [[ $line == https://* ]]; then
			jq -nc --arg url "$line" '{url: $url}'
		fi
	done <"$tmp/out"
	wait "$pid" || status=$?
	if ((status != 0)); then
		report_error
		return "$status"
	fi
	jq -nc '{signedIn: true}'
}

logout() {
	cli logout --force >/dev/null
	jq -nc '{signedIn: false}'
}

# Every active item of every vault, without secrets: [{share, id, title, type, vault}] by title.
list() {
	local vaults share
	vaults=$(cli vault list --output json)
	while IFS= read -r share; do
		cli item list --share-id "$share" --filter-state active --output json
	done < <(jq -r '.vaults[].share_id' <<<"$vaults") |
		jq -sc --argjson vaults "$vaults" '
			($vaults.vaults | map({(.share_id): .name}) | add // {}) as $names
			| [.[].items[] | {share: .share_id, id, title, type: (.item_type // ""), vault: ($names[.share_id] // "")}]
			| sort_by(.title | ascii_downcase)'
}

# The non-secret side of one item, plus which secrets it has. `primary` is the field Enter copies;
# `apiKeys` are the custom fields named like an API key ("SONARR_API_KEY", "API key"), by their
# position, since two of them may share a name.
# The content is serde's externally tagged ItemContent from proton-pass-types, e.g.
# {"Login": {"username", "email", "password", "urls", "totp_uri", …}}.
details() {
	cli item view --share-id "$1" --item-id "$2" --output json | jq -c '
		def filled: . != null and . != "" and . != [];
		.item as $item
		| ($item.content.content // {}) as $content
		| (if ($content | type) == "object" then ($content | keys_unsorted[0] // "") else ($content | tostring) end) as $tag
		| (if ($content | type) == "object" then $content[$tag] else null end) as $tagged
		| (if ($tagged | type) == "object" then $tagged else (first($item | .. | objects | select(has("urls") and has("password"))) // {}) end) as $data
		| ($tag | gsub("(?<a>[a-z0-9])(?<b>[A-Z])"; "\(.a)_\(.b)") | ascii_downcase) as $type
		| {
			type: $type,
			username: ($data.username // ""),
			email: ((if $type == "alias" then $item.alias_email else $data.email end) // ""),
			urls: [$data.urls[]? | strings | select(. != "")],
			hasPassword: ($data.password | filled),
			hasTotp: ($data.totp_uri | filled),
			hasNote: ($item.content.note | filled),
			primary: (
				if ($type == "login" or $type == "wifi") and ($data.password | filled) then "password"
				elif $type == "credit_card" and ($data.number | filled) then "number"
				elif $type == "ssh_key" and ($data.private_key | filled) then "private_key"
				elif $type == "note" and ($item.content.note | filled) then "note"
				else "" end),
			apiKeys: [($item.content.extra_fields // []) | to_entries[]
				| select((.value.name // "") | test("api[ _-]?key"; "i"))
				| {index: .key, name: .value.name}]
		}'
}

# One field (password, totp → current code, extra:N → the Nth custom field, …) onto the
# clipboard, marked sensitive so clipboard managers skip it, and off it again after $clear_after
# seconds unless something else was copied since. Read into a variable (not piped) so a failed
# lookup leaves the clipboard alone; only its hash outlives this function.
copy() {
	local value hash token
	if [[ $3 =~ ^extra:([0-9]+)$ ]]; then
		# By position: pass-cli's --field takes a name, and custom field names can repeat.
		value=$(cli item view --share-id "$1" --item-id "$2" --output json |
			jq -j --argjson i "${BASH_REMATCH[1]}" '.item.content.extra_fields[$i].content // {} | to_entries[0].value // ""')
	else
		value=$(cli item view --share-id "$1" --item-id "$2" --field "$3")
	fi
	if [[ -z $value ]]; then
		echo "The item has no ${3/#extra:*/such field}" >&2
		return 1
	fi
	hash=$(printf '%s' "$value" | sha256sum)
	# wl-copy keeps serving from a forked child; it must not hold the caller's pipes open.
	if ! printf '%s' "$value" | wl-copy --sensitive >/dev/null 2>&1 9>&-; then
		unset value
		echo "Couldn't write to the clipboard" >&2
		return 1
	fi
	unset value

	# A newer copy takes over the countdown, so re-copying the same secret starts it afresh.
	token=$(date +%s%N)
	printf '%s' "$token" >"$XDG_RUNTIME_DIR/quickshell-pass-clear"
	(
		sleep "$clear_after"
		if [[ $(<"$XDG_RUNTIME_DIR/quickshell-pass-clear") == "$token" ]]; then
			rm -f "$XDG_RUNTIME_DIR/quickshell-pass-clear"
			if [[ $(wl-paste --no-newline 2>/dev/null | sha256sum) == "$hash" ]]; then
				wl-copy --clear
			fi
		fi
	) </dev/null >/dev/null 2>&1 9>&- &
	jq -nc --argjson clearAfter "$clear_after" '{clearAfter: $clearAfter}'
}

case "${1:-}" in
status | logout | list | details | copy) lock shared ;;
login) lock exclusive ;;
esac

case "${1:-}" in
status) status ;;
login) login ;;
logout) logout ;;
list) list ;;
details) details "$2" "$3" ;;
copy) copy "$2" "$3" "$4" ;;
*)
	echo "usage: quickshell-pass status|login|logout|list|details SHARE ITEM|copy SHARE ITEM FIELD" >&2
	exit 2
	;;
esac
