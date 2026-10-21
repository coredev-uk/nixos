pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Primary connection summary on top of Quickshell.Networking (NetworkManager).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool hasWifi: wifiDevice !== null && Networking.wifiHardwareEnabled

    readonly property string type: wiredDevice ? "ethernet" : wifiNetwork ? "wifi" : "disconnected"
    readonly property string name: wiredDevice ? (wiredDevice.network?.name ?? wiredDevice.name) : (wifiNetwork?.name ?? "")
    readonly property real signal: wifiNetwork?.signalStrength ?? 0
    readonly property string iface: wiredDevice?.name ?? (wifiNetwork ? wifiDevice.name : "")
    property string ip: ""

    onIfaceChanged: refreshIp()
    Component.onCompleted: refreshIp()

    function refreshIp() {
        if (iface === "") {
            ip = "";
            return;
        }
        ipProc.command = ["ip", "-j", "-4", "addr", "show", "dev", iface];
        ipProc.running = true;
    }

    Process {
        id: ipProc
        stdout: StdioCollector {
            id: ipOut
            onStreamFinished: {
                try {
                    root.ip = JSON.parse(ipOut.text)[0]?.addr_info?.[0]?.local ?? "";
                } catch (e) {
                    root.ip = "";
                }
            }
        }
    }
}
