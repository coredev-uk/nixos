#!/usr/bin/env bash
# network.sh --status|--wifi-list|--connect SSID [PASS]|--disconnect

status() {
	local type="disconnected" name="" ip="" signal=0 iface="" wifi_hw="false"

	if nmcli -t -f WIFI-HW general status 2>/dev/null | grep -q "enabled"; then
		wifi_hw="true"
	fi

	local active
	active=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -v '^lo:' | head -1)

	if [[ -n "$active" ]]; then
		name=$(echo "$active" | cut -d: -f1)
		local ctype
		ctype=$(echo "$active" | cut -d: -f2 | tr "[:upper:]" "[:lower:]")
		iface=$(echo "$active" | cut -d: -f3)

		case "$ctype" in
		*wireless* | *wifi* | *802-11*)
			type="wifi"
			signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null |
				grep '^\*' | head -1 | cut -d: -f2)
			signal=${signal:-0}
			;;
		*ethernet* | *wired*)
			type="ethernet"
			signal=100
			;;
		esac

		if [[ -n "$iface" ]]; then
			ip=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
		fi
	fi

	printf '{"type":"%s","name":"%s","ip":"%s","signal":%d,"iface":"%s","wifi_hw":%s}\n' \
		"$type" "$name" "$ip" "$signal" "$iface" "$wifi_hw"
}

wifi_list() {
	nmcli device wifi rescan 2>/dev/null
	sleep 1

	local output="["
	local first=true

	while IFS=: read -r ssid signal security in_use; do
		[[ -z "$ssid" ]] && continue
		ssid="${ssid//\"/\\\"}"

		local connected="false"
		[[ "$in_use" == "*" ]] && connected="true"

		local secured="false"
		[[ -n "$security" && "$security" != "--" ]] && secured="true"

		if [[ "$first" == "true" ]]; then
			first=false
		else
			output+=","
		fi

		output+=$(printf '{"ssid":"%s","signal":%d,"security":"%s","secured":%s,"connected":%s}' \
			"$ssid" "$signal" "$security" "$secured" "$connected")
	done < <(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE device wifi list 2>/dev/null)

	output+="]"
	echo "$output"
}

connect_wifi() {
	local ssid="$1"
	local password="$2"

	if [[ -z "$ssid" ]]; then
		echo '{"success":false,"error":"No SSID provided"}'
		return 1
	fi

	local result
	if [[ -n "$password" ]]; then
		result=$(nmcli device wifi connect "$ssid" password "$password" 2>&1)
	else
		result=$(nmcli device wifi connect "$ssid" 2>&1)
	fi

	if [[ $? -eq 0 ]]; then
		echo '{"success":true,"error":""}'
	else
		result="${result//\"/\\\"}"
		echo "{\"success\":false,\"error\":\"$result\"}"
	fi
}

disconnect_wifi() {
	local iface
	iface=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ':wifi' | cut -d: -f1 | head -1)

	if [[ -n "$iface" ]]; then
		nmcli device disconnect "$iface" 2>/dev/null
		echo '{"success":true}'
	else
		echo '{"success":false,"error":"No WiFi device found"}'
	fi
}

toggle_wifi() {
	local enabled
	enabled=$(nmcli -t -f WIFI general status 2>/dev/null)
	if [[ "$enabled" == "enabled" ]]; then
		nmcli radio wifi off 2>/dev/null
	else
		nmcli radio wifi on 2>/dev/null
	fi
}

case "$1" in
--status) status ;;
--wifi-list) wifi_list ;;
--connect) connect_wifi "$2" "$3" ;;
--disconnect) disconnect_wifi ;;
--toggle) toggle_wifi ;;
*) status ;;
esac
