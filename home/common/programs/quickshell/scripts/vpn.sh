# quickshell-vpn --status|--countries|--connect [COUNTRY]|--disconnect
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

# protonvpn prints "Connected to <SERVER> in <City, Country>. " and "Your new IP address is <IP>."
connect() {
	local output server location ip
	output=$(protonvpn connect "$@" 2>&1) || true
	server=$(sed -n 's/^Connected to \([^ ]*\) in .*$/\1/p' <<<"$output")
	location=$(sed -n 's/^Connected to [^ ]* in \(.*\)\. *$/\1/p' <<<"$output")
	ip=$(sed -n 's/^Your new IP address is \(.*\)\.$/\1/p' <<<"$output")

	if [[ -n "$server" ]]; then
		notify "VPN connected" "$(printf '%s (%s)\nIP: %s' "$location" "$server" "${ip:-unknown}")"
	else
		notify --urgency=critical "VPN connection failed" "$(grep -v '^[[:space:]]*$' <<<"$output" | tail -n1)"
		return 1
	fi
}

disconnect() {
	local output
	if output=$(protonvpn disconnect 2>&1); then
		notify "VPN disconnected"
	else
		notify --urgency=critical "VPN disconnect failed" "$(grep -v '^[[:space:]]*$' <<<"$output" | tail -n1)"
		return 1
	fi
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
*)
	echo "usage: quickshell-vpn --status|--countries|--connect [COUNTRY]|--disconnect" >&2
	exit 1
	;;
esac
