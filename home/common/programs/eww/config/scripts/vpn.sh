#!/usr/bin/env bash
# vpn.sh --status|--countries|--connect [COUNTRY]|--disconnect

status() {
	local connected="false" ip="" server=""

	if ip a show proton0 &>/dev/null; then
		connected="true"
		ip=$(ip -o -4 addr show proton0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
		local conn_name
		conn_name=$(nmcli -t -f NAME connection show --active 2>/dev/null | grep '^ProtonVPN' | head -1)
		server="${conn_name#ProtonVPN }"
	fi

	printf '{"connected":%s,"ip":"%s","server":"%s"}\n' "$connected" "$ip" "$server"
}

code_to_flag() {
	local code="$1"
	# Map non-standard codes to ISO 3166-1 alpha-2
	case "$code" in
	UK) code="GB" ;;
	esac
	local c1 c2
	c1=$(printf '%d' "'${code:0:1}")
	c2=$(printf '%d' "'${code:1:1}")
	# Regional indicator symbols: U+1F1E6 = 0x1F1E6, 'A' = 65
	printf "\\U$(printf '%08X' $((0x1F1E6 + c1 - 65)))\\U$(printf '%08X' $((0x1F1E6 + c2 - 65)))"
}

countries() {
	local output="["
	local first=true

	while IFS= read -r line; do
		[[ "$line" =~ ^[[:space:]]*$ ]] && continue
		[[ "$line" =~ ^Country ]] && continue
		[[ "$line" =~ ^[-]+ ]] && continue

		local code name
		code=$(echo "$line" | awk '{print $NF}')
		name=$(echo "$line" | sed "s/[[:space:]]*${code}[[:space:]]*$//" | sed 's/^[[:space:]]*//')

		[[ -z "$name" || -z "$code" ]] && continue
		[[ ${#code} -ne 2 ]] && continue

		name="${name//\"/\\\"}"
		local flag
		flag=$(code_to_flag "$code")

		if [[ "$first" == "true" ]]; then
			first=false
		else
			output+=","
		fi

		output+=$(printf '{"name":"%s","code":"%s","flag":"%s"}' "$name" "$code" "$flag")
	done < <(protonvpn countries 2>/dev/null)

	output+="]"
	echo "$output"
}

connect() {
	local country="$1"
	local result

	if [[ -n "$country" ]]; then
		result=$(protonvpn connect --country "$country" 2>&1)
	else
		result=$(protonvpn connect 2>&1)
	fi

	if ip a show proton0 &>/dev/null; then
		echo '{"success":true,"error":""}'
	else
		result="${result//\"/\\\"}"
		echo "{\"success\":false,\"error\":\"$result\"}"
	fi
}

disconnect() {
	protonvpn disconnect 2>&1 >/dev/null

	if ! ip a show proton0 &>/dev/null; then
		echo '{"success":true}'
	else
		echo '{"success":false,"error":"Failed to disconnect"}'
	fi
}

case "$1" in
--status) status ;;
--countries) countries ;;
--connect) connect "$2" ;;
--disconnect) disconnect ;;
*) status ;;
esac
