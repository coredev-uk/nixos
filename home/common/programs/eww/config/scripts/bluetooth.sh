#!/usr/bin/env bash
# bluetooth.sh --status|--devices|--scan-start|--scan-stop|--connect MAC|--disconnect MAC|--pair MAC|--toggle-power

bt_status() {
	local powered="false" scanning="false"

	local info
	info=$(bluetoothctl show 2>/dev/null)

	if echo "$info" | grep -q "Powered: yes"; then
		powered="true"
	fi

	if echo "$info" | grep -q "Discovering: yes"; then
		scanning="true"
	fi

	printf '{"powered":%s,"scanning":%s}\n' "$powered" "$scanning"
}

devices() {
	local output="["
	local first=true

	while read -r _ mac name; do
		[[ -z "$mac" ]] && continue

		local info connected="false" paired="false" trusted="false" icon=""
		info=$(bluetoothctl info "$mac" 2>/dev/null)

		if echo "$info" | grep -q "Connected: yes"; then
			connected="true"
		fi

		if echo "$info" | grep -q "Paired: yes"; then
			paired="true"
		fi

		if echo "$info" | grep -q "Trusted: yes"; then
			trusted="true"
		fi

		icon=$(echo "$info" | awk -F': ' '/Icon:/{print $2}')
		name="${name//\"/\\\"}"

		if [[ "$first" == "true" ]]; then
			first=false
		else
			output+=","
		fi

		output+=$(printf '{"mac":"%s","name":"%s","connected":%s,"paired":%s,"trusted":%s,"icon":"%s"}' \
			"$mac" "$name" "$connected" "$paired" "$trusted" "$icon")
	done < <(bluetoothctl devices 2>/dev/null)

	output+="]"
	echo "$output"
}

scan_start() {
	(
		bluetoothctl scan on &>/dev/null &
		local pid=$!
		sleep 30
		kill "$pid" 2>/dev/null
		bluetoothctl scan off &>/dev/null
	) &
	echo '{"success":true}'
}

scan_stop() {
	bluetoothctl scan off &>/dev/null
	echo '{"success":true}'
}

connect_device() {
	local mac="$1"
	[[ -z "$mac" ]] && echo '{"success":false,"error":"No MAC address"}' && return 1

	bluetoothctl trust "$mac" &>/dev/null
	local result
	result=$(bluetoothctl connect "$mac" 2>&1)

	if echo "$result" | grep -q "Connection successful"; then
		echo '{"success":true,"error":""}'
	else
		result="${result//\"/\\\"}"
		echo "{\"success\":false,\"error\":\"$result\"}"
	fi
}

disconnect_device() {
	local mac="$1"
	[[ -z "$mac" ]] && echo '{"success":false,"error":"No MAC address"}' && return 1

	bluetoothctl disconnect "$mac" &>/dev/null
	echo '{"success":true}'
}

pair_device() {
	local mac="$1"
	[[ -z "$mac" ]] && echo '{"success":false,"error":"No MAC address"}' && return 1

	local result
	result=$(bluetoothctl pair "$mac" 2>&1)

	if echo "$result" | grep -q "Pairing successful"; then
		bluetoothctl trust "$mac" &>/dev/null
		echo '{"success":true,"error":""}'
	else
		result="${result//\"/\\\"}"
		echo "{\"success\":false,\"error\":\"$result\"}"
	fi
}

toggle_power() {
	local info
	info=$(bluetoothctl show 2>/dev/null)

	if echo "$info" | grep -q "Powered: yes"; then
		bluetoothctl power off &>/dev/null
		echo '{"powered":false}'
	else
		bluetoothctl power on &>/dev/null
		echo '{"powered":true}'
	fi
}

case "$1" in
--status) bt_status ;;
--devices) devices ;;
--scan-start) scan_start ;;
--scan-stop) scan_stop ;;
--connect) connect_device "$2" ;;
--disconnect) disconnect_device "$2" ;;
--pair) pair_device "$2" ;;
--toggle-power) toggle_power ;;
*) bt_status ;;
esac
