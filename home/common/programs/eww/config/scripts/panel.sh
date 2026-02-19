#!/usr/bin/env bash
# panel.sh - Helper for network panel navigation and actions
# Handles eww variable updates that require command substitution with JSON output

SCRIPTS_DIR="$(dirname "$0")"
EWW_CMD="eww"

case "$1" in
--open-wifi)
	list=$("$SCRIPTS_DIR/network.sh" --wifi-list)
	$EWW_CMD update wifi_list="$list"
	$EWW_CMD update net_panel_view=1
	;;
--open-vpn)
	countries=$("$SCRIPTS_DIR/vpn.sh" --countries)
	$EWW_CMD update vpn_countries="$countries"
	$EWW_CMD update net_panel_view=2
	;;
--open-bt)
	devices=$("$SCRIPTS_DIR/bluetooth.sh" --devices)
	$EWW_CMD update bt_devices="$devices"
	$EWW_CMD update net_panel_view=3
	;;
--refresh-bt)
	devices=$("$SCRIPTS_DIR/bluetooth.sh" --devices)
	$EWW_CMD update bt_devices="$devices"
	;;
--vpn-toggle)
	if ip a show proton0 &>/dev/null; then
		"$SCRIPTS_DIR/vpn.sh" --disconnect
	else
		"$SCRIPTS_DIR/vpn.sh" --connect "$2"
	fi
	sleep 2
	$EWW_CMD poll vpn_status
	;;
--vpn-connect-country)
	"$SCRIPTS_DIR/vpn.sh" --connect "$2"
	sleep 2
	$EWW_CMD poll vpn_status
	$EWW_CMD close network_panel network_panel_dismiss
	;;
--bt-toggle-power)
	"$SCRIPTS_DIR/bluetooth.sh" --toggle-power
	sleep 1
	$EWW_CMD poll bt_status
	;;
--bt-connect)
	"$SCRIPTS_DIR/bluetooth.sh" --connect "$2"
	devices=$("$SCRIPTS_DIR/bluetooth.sh" --devices)
	$EWW_CMD update bt_devices="$devices"
	;;
--bt-disconnect)
	"$SCRIPTS_DIR/bluetooth.sh" --disconnect "$2"
	devices=$("$SCRIPTS_DIR/bluetooth.sh" --devices)
	$EWW_CMD update bt_devices="$devices"
	;;
--bt-scan)
	"$SCRIPTS_DIR/bluetooth.sh" --scan-start
	sleep 3
	devices=$("$SCRIPTS_DIR/bluetooth.sh" --devices)
	$EWW_CMD update bt_devices="$devices"
	;;
--wifi-toggle)
	"$SCRIPTS_DIR/network.sh" --toggle
	sleep 1
	$EWW_CMD poll net_status
	;;
esac
