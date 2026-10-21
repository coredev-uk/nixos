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

case "${1:-}" in
--status) status ;;
--countries) countries ;;
--connect)
	if [[ -n "${2:-}" ]]; then
		protonvpn connect --country "$2"
	else
		protonvpn connect
	fi
	;;
--disconnect) protonvpn disconnect ;;
*)
	echo "usage: quickshell-vpn --status|--countries|--connect [COUNTRY]|--disconnect" >&2
	exit 1
	;;
esac
