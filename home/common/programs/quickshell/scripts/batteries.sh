# Prints one JSON array of peripheral batteries for the quickshell panel:
#   [{"name": "...", "short": "...", "kind": "mouse|headset|keyboard|...",
#     "level": 0-100 | null, "charging": bool}]
# short = name without the leading brand word ("Razer Viper V3 Pro" -> "Viper V3 Pro").
# level null = device present but not reporting (e.g. headset switched off).
#
# Sources, each optional so the script works on hosts without them:
#   - OpenRazer daemon (session D-Bus, org.razer): every device with razer.device.power
#   - HeadsetControl (headsetcontrol on PATH, installed per host)

razer() {
  local serial path name kind level charging
  busctl --user --json=short call org.razer /org/razer razer.devices getDevices 2>/dev/null |
    jq -r '.data[0][]' |
    while IFS= read -r serial; do
      path="/org/razer/device/$serial"
      # Wired-only devices have no razer.device.power interface: skip them.
      level=$(busctl --user --json=short call org.razer "$path" razer.device.power getBattery 2>/dev/null | jq '.data[0]') || continue
      charging=$(busctl --user --json=short call org.razer "$path" razer.device.power isCharging 2>/dev/null | jq '.data[0]') || charging=false
      name=$(busctl --user --json=short call org.razer "$path" razer.device.misc getDeviceName 2>/dev/null | jq -r '.data[0]') || name="Razer device"
      kind=$(busctl --user --json=short call org.razer "$path" razer.device.misc getDeviceType 2>/dev/null | jq -r '.data[0]') || kind=device
      jq -nc --arg name "${name% (Wireless)}" --arg kind "$kind" --argjson level "$level" --argjson charging "$charging" \
        '{name: $name, kind: $kind, level: ($level | round), charging: $charging}'
    done
}

headsets() {
  command -v headsetcontrol >/dev/null || return 0
  headsetcontrol -b -o json 2>/dev/null |
    jq -c '.devices[]? | {
      name: .device,
      kind: "headset",
      level: (if (.battery.status == "BATTERY_AVAILABLE" or .battery.status == "BATTERY_CHARGING") and .battery.level >= 0
              then .battery.level else null end),
      charging: (.battery.status == "BATTERY_CHARGING")
    }' || true
}

# A missing source (no OpenRazer daemon, no headsetcontrol) must not drop the other.
{
  razer || true
  headsets || true
} | jq -sc 'map(. + {short: (.name | sub("^\\S+\\s+"; ""))})'
