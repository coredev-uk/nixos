# quickshell-pass status|login|logout|list|details SHARE ITEM|copy SHARE ITEM FIELD|icons DOMAIN…
# Proton Pass for the quick-access window (modules/PassQuickAccess.qml): JSON on stdout; on failure
# one error line on stderr and non-zero exit. Secrets only ever go to the clipboard.

# pass-cli's default key store (kernel keyring) is denied here and gone after reboot; gnome-keyring
# keeps the session. Set here too since the quickshell service can start before session variables exist.
export PROTON_PASS_LINUX_KEYRING=dbus
# Updates come with the Nix package:
export PROTON_PASS_NO_UPDATE_CHECK=1

# Seconds a copied secret stays on the clipboard.
clear_after=${QUICKSHELL_PASS_CLEAR_AFTER:-45}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A pending web login makes pass-cli's store unsafe to share: any other command deletes the
# half-made session and the login fails ("Error persisting session store"). Login holds this lock
# exclusively, the rest share it and refuse during a login. Long-lived children (wl-copy, the
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

# pass-cli logs tracing lines and anyhow chains to stderr; reduce to one readable line. Reads
# $tmp/errors unless given another file.
report_error() {
	local line message="" cause="" fallback="" errors=${1:-$tmp/errors}
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
	done <"$errors"
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

# Web login: prints {"url": …} once pass-cli has the sign-in page, then {"signedIn": true}. SIGTERM cancels.
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

# Active items of vaults not in $QUICKSHELL_PASS_HIDDEN_VAULTS (one per line, set in default.nix),
# without secrets: [{share, id, title, type, vault, domain}] by title. `domain` is a login's
# website for its icon (host of its first address, minus "www."), "" if none or a private address
# (kept off the icon service). Only --show-secrets lists addresses; as in details, secrets stop at jq.
# Each pass-cli run costs ~1 s (keyring + API connection), so vaults are listed in parallel; the
# vault list goes first and alone so an expired access token is refreshed once, not per run.
list() {
	local vaults i status failed=-1 failure=0
	local -a shares pids files
	vaults=$(cli vault list --output json |
		jq -c --arg hidden "${QUICKSHELL_PASS_HIDDEN_VAULTS:-}" \
			'($hidden | split("\n")) as $hidden
			| .vaults |= map(select(.name as $name | $hidden | index($name) | not))')
	mapfile -t shares < <(jq -r '.vaults[].share_id' <<<"$vaults")
	for i in "${!shares[@]}"; do
		pass-cli item list --share-id "${shares[i]}" --filter-state active --output json --show-secrets \
			>"$tmp/items.$i" 2>"$tmp/errors.$i" &
		pids[i]=$!
		files[i]=$tmp/items.$i
	done
	# Wait for all before reporting a failure, so none outlives the temporary directory.
	for i in "${!pids[@]}"; do
		status=0
		wait "${pids[i]}" || status=$?
		if ((status != 0 && failed < 0)); then
			failed=$i
			failure=$status
		fi
	done
	if ((failed >= 0)); then
		report_error "$tmp/errors.$failed"
		return "$failure"
	fi
	# With every vault hidden there are no files; jq reads the empty stdin instead.
	jq -sc --argjson vaults "$vaults" '
		def domain:
			[.content.content | objects | .Login.urls[]? | strings | ascii_downcase
				| capture("^https?://([^/?#@]*@)?(?<host>[^/?#:]+)").host][0] // ""
			| ltrimstr("www.")
			| if test("^[a-z0-9-]+(\\.[a-z0-9-]+)+$") and (test("^[0-9.]+$") | not)
				and (test("\\.(local|lan|home|internal|arpa|localhost|test)$") | not)
			then . else "" end;
		($vaults.vaults | map({(.share_id): .name}) | add // {}) as $names
		| [.[].items[]
			| (.content.content | if type == "object" then keys_unsorted[0] // "" else tostring end) as $tag
			| {
				share: .share_id,
				id,
				title: (.content.title // ""),
				type: ($tag | gsub("(?<a>[a-z0-9])(?<b>[A-Z])"; "\(.a)_\(.b)") | ascii_downcase),
				vault: ($names[.share_id] // ""),
				domain: domain
			}]
		| sort_by(.title | ascii_downcase)' "${files[@]}" </dev/null
}

# Non-secret side of one item plus which secrets it has. `primary` is the field Enter copies;
# `apiKeys` are custom fields named like an API key ("SONARR_API_KEY"), by position since names can repeat.
# Content is serde's externally tagged ItemContent from proton-pass-types, e.g.
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

# One field (password, totp → current code, extra:N → Nth custom field, …) onto the clipboard,
# marked sensitive so clipboard managers skip it, cleared after $clear_after seconds unless
# something else was copied. Read into a variable (not piped) so a failed lookup leaves the
# clipboard alone.
copy() {
	local value hash token
	if [[ $3 =~ ^extra:([0-9]+)$ ]]; then
		# By position: --field takes a name and custom field names can repeat.
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
	# wl-copy serves from a forked child; it must not hold the caller's pipes open.
	if ! printf '%s' "$value" | wl-copy --sensitive >/dev/null 2>&1 9>&-; then
		unset value
		echo "Couldn't write to the clipboard" >&2
		return 1
	fi
	unset value

	# A newer copy takes over the countdown.
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

# Website icons, from DuckDuckGo's favicon service, else Bitwarden's (Proton's needs the app's
# session), cached for a month. A website neither has falls back to its parent
# (signin.aws.amazon.com → aws.amazon.com → amazon.com); one with no icon at all is remembered for
# the month and takes the icon of another website on the same site. Prints a {domain, path} line
# per website with an icon as soon as it has one; failures are left for the next run.
icons() {
	local dir=${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-pass/icons domain json_dir
	local -a wanted=() missing=()
	mkdir -p "$dir"
	find "$dir" -type f -mtime +30 -delete
	json_dir=$(jq -rn --arg dir "$dir" '$dir | tojson | .[1:-1]')
	for domain; do
		[[ $domain =~ ^[a-z0-9-]+(\.[a-z0-9-]+)+$ ]] || continue
		wanted+=("$domain")
		if [[ -e $dir/$domain.ico ]]; then
			found_icon "$domain"
		elif [[ ! -e $dir/$domain.none ]]; then
			fetch_icon &
			while (($(jobs -rp | wc -l) >= 8)); do
				wait -n || true
			done
		fi
	done
	wait

	for domain in "${wanted[@]}"; do
		[[ -e $dir/$domain.none ]] && missing+=("$domain")
	done
	((${#missing[@]} > 0)) || return 0
	# Of the icons on each site, the site's own, else the shortest website's.
	local file name
	local -A suffixes=() best=()
	load_suffixes
	for file in "$dir"/*.ico; do
		[[ -e $file ]] || continue
		name=${file##*/}
		name=${name%.ico}
		site "$name"
		if [[ -z ${best[$REPLY]-} || $name == "$REPLY" ||
			(${best[$REPLY]} != "$REPLY" && ${#name} -lt ${#best[$REPLY]}) ]]; then
			best[$REPLY]=$name
		fi
	done
	for domain in "${missing[@]}"; do
		site "$domain"
		if [[ -n ${best[$REPLY]-} ]]; then
			found_icon "$domain" "${best[$REPLY]}"
		fi
	done
}

# Icon helpers; set $dir, $json_dir (JSON-escaped) and $domain.
# found_icon DOMAIN [ICON_DOMAIN]: DOMAIN uses ICON_DOMAIN's icon (its own by default).
found_icon() {
	printf '{"domain":"%s","path":"%s/%s.ico"}\n' "$1" "$json_dir" "${2:-$1}"
}

# Public suffix list rules into `suffixes`.
load_suffixes() {
	local rule
	while IFS= read -r rule; do
		[[ -z $rule || $rule == //* ]] || suffixes[$rule]=1
	done <"$PUBLIC_SUFFIX_LIST"
}

# The site a host belongs to (REPLY): the label before its public suffix (login.example.co.uk →
# example.co.uk), by longest matching rule; "!" rules are exceptions to a "*." one.
site() {
	local name=$1 above=$1
	REPLY=$1
	while :; do
		if [[ -n ${suffixes["!$name"]-} ]]; then
			REPLY=$name
			return
		fi
		if [[ -n ${suffixes[$name]-} || ($name == *.* && -n ${suffixes["*.${name#*.}"]-}) ]]; then
			REPLY=$above
			return
		fi
		# No rule at all: the top-level domain is the suffix.
		if [[ $name != *.* ]]; then
			REPLY=$above
			return
		fi
		above=$name
		name=${name#*.}
	done
}

fetch_icon() {
	local host=$domain part=$dir/.$domain.part url code
	while :; do
		for url in "https://icons.duckduckgo.com/ip3/$host.ico" "https://icons.bitwarden.net/$host/icon.png"; do
			code=$(curl -s --max-time 10 -o "$part" -w '%{http_code}' "$url") || code=000
			if [[ $code == 200 && -s $part ]] && ! placeholder "$part"; then
				# Some are WebP, which the shell's Qt can't read.
				if [[ $(head -c 12 "$part" | tail -c 4 | tr -d '\0') == WEBP ]]; then
					if ! dwebp -quiet "$part" -o "$part.png"; then
						rm -f "$part" "$part.png"
						return
					fi
					mv "$part.png" "$part"
				fi
				mv "$part" "$dir/$domain.ico"
				found_icon "$domain"
				return
			fi
			rm -f "$part"
			# 404 = no icon (as are an empty 200 or a placeholder); anything else may work next time.
			if [[ $code != 404 && $code != 200 ]]; then
				return
			fi
		done
		if [[ $host == *.*.* ]]; then
			host=${host#*.}
		else
			: >"$dir/$domain.none"
			return
		fi
	done
}

# Bitwarden's 200 stand-in for a missing icon: a 19×19 PNG (IHDR from byte 12 gives the size).
placeholder() {
	[[ $(od -An -tx1 -j12 -N12 "$1" | tr -d ' \n') == 494844520000001300000013 ]]
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
icons) icons "${@:2}" ;;
*)
	echo "usage: quickshell-pass status|login|logout|list|details SHARE ITEM|copy SHARE ITEM FIELD|icons DOMAIN…" >&2
	exit 2
	;;
esac
