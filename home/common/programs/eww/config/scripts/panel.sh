#!/usr/bin/env bash
# panel.sh - Helper for network panel navigation and actions
# Handles eww variable updates that require command substitution with JSON output

EWW_CMD="eww"
NETWORK_CMD="eww-network"
VPN_CMD="eww-vpn"
BLUETOOTH_CMD="eww-bluetooth"

case "$1" in
--open-wifi)
	list=$("$NETWORK_CMD" --wifi-list)
	"$EWW_CMD" update wifi_list="$list"
	"$EWW_CMD" update net_panel_view=1
	;;
--open-vpn)
	countries=$("$VPN_CMD" --countries)
	"$EWW_CMD" update vpn_countries="$countries"
	"$EWW_CMD" update net_panel_view=2
	;;
--open-bt)
	devices=$("$BLUETOOTH_CMD" --devices)
	"$EWW_CMD" update bt_devices="$devices"
	"$EWW_CMD" update net_panel_view=3
	;;
--refresh-bt)
	devices=$("$BLUETOOTH_CMD" --devices)
	"$EWW_CMD" update bt_devices="$devices"
	;;
--vpn-toggle)
	if ip a show proton0 &>/dev/null; then
		"$VPN_CMD" --disconnect
	else
		"$VPN_CMD" --connect "$2"
	fi
	sleep 2
	"$EWW_CMD" poll vpn_status
	;;
--vpn-connect-country)
	"$VPN_CMD" --connect "$2"
	sleep 2
	"$EWW_CMD" poll vpn_status
	"$EWW_CMD" close network_panel network_panel_dismiss
	;;
--bt-toggle-power)
	"$BLUETOOTH_CMD" --toggle-power
	sleep 1
	"$EWW_CMD" poll bt_status
	;;
--bt-connect)
	"$BLUETOOTH_CMD" --connect "$2"
	devices=$("$BLUETOOTH_CMD" --devices)
	"$EWW_CMD" update bt_devices="$devices"
	;;
--bt-disconnect)
	"$BLUETOOTH_CMD" --disconnect "$2"
	devices=$("$BLUETOOTH_CMD" --devices)
	"$EWW_CMD" update bt_devices="$devices"
	;;
--bt-scan)
	"$BLUETOOTH_CMD" --scan-start
	sleep 3
	devices=$("$BLUETOOTH_CMD" --devices)
	"$EWW_CMD" update bt_devices="$devices"
	;;
--wifi-toggle)
	"$NETWORK_CMD" --toggle
	sleep 1
	"$EWW_CMD" poll net_status
	;;
esac
