# quickshell-vpn --status|--countries|--connect [COUNTRY]|--disconnect|--notify-state
# Output is tab separated so the shell never has to parse hand-built JSON.

status() {
	if ip link show proton0 &>/dev/null; then
		local ip server
		ip=$(ip -o -4 addr show proton0 | awk '{print $4}' | cut -d/ -f1)
		server=$(nmcli -t -f NAME connection show --active | grep -m1 '^ProtonVPN' || true)
		printf 'true\t%s\t%s\n' "$ip" "${server#ProtonVPN }"
	else
		printf 'false\t\t\n'
	fi
}

# "<CODE>\t<Country name>" per line; header and separator rows have no 2-letter code.
countries() {
	protonvpn countries list 2>/dev/null | awk '
		$NF ~ /^[A-Z][A-Z]$/ && NF >= 2 {
			code = $NF
			$NF = ""
			sub(/[[:space:]]+$/, "")
			sub(/^[[:space:]]+/, "")
			print code "\t" $0
		}'
}

notify() {
	notify-send --app-name=ProtonVPN --icon=network-vpn "$@"
}

last_line() {
	grep -v '^[[:space:]]*$' <<<"$1" | tail -n1
}

# Failures only: the bar calls --notify-state whenever the tunnel comes up or goes down,
# which also covers connections made outside the bar. The reason also goes to stderr, where
# the panel reads it.
connect() {
	local output
	if ! output=$(protonvpn connect "$@" 2>&1) || ! grep -q '^Connected to ' <<<"$output"; then
		notify --urgency=critical "VPN connection failed" "$(last_line "$output")"
		last_line "$output" >&2
		return 1
	fi
}

disconnect() {
	local output
	if ! output=$(protonvpn disconnect 2>&1); then
		notify --urgency=critical "VPN disconnect failed" "$(last_line "$output")"
		last_line "$output" >&2
		return 1
	fi
}

# Proton's location API reports the public IP as seen through the tunnel.
notify_state() {
	if ! ip link show proton0 &>/dev/null; then
		notify "VPN disconnected"
		return
	fi

	local server location ip
	server=$(nmcli -t -f NAME connection show --active | grep -m1 '^ProtonVPN' || true)
	server=${server#ProtonVPN }
	# "Server: <SERVER> in <City, Country>"
	location=$(protonvpn status 2>/dev/null | sed -n 's/^Server: [^ ]* in \(.*\)$/\1/p' || true)
	ip=$(curl -fsS --max-time 5 --retry 2 https://vpn-api.proton.me/vpn/v1/location | jq -r '.IP // empty' || true)
	notify "VPN connected" "$(printf '%s (%s)\nIP: %s' "${location:-Unknown location}" "${server:-unknown server}" "${ip:-unknown}")"
}

case "${1:-}" in
--status) status ;;
--countries) countries ;;
--connect)
	if [[ -n "${2:-}" ]]; then
		connect --country "$2"
	else
		connect
	fi
	;;
--disconnect) disconnect ;;
--notify-state) notify_state ;;
*)
	echo "usage: quickshell-vpn --status|--countries|--connect [COUNTRY]|--disconnect|--notify-state" >&2
	exit 1
	;;
esac
