pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Primary connection summary on top of Quickshell.Networking (NetworkManager).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    // The connected wired device, else one with a cable in, else any: the panel's Ethernet row
    // shows it even while it is down.
    readonly property var wiredDevice: {
        const wired = devices.filter(d => d.type === DeviceType.Wired);
        return wired.find(d => d.connected) ?? wired.find(d => d.hasLink) ?? wired[0] ?? null;
    }
    readonly property bool wiredConnected: wiredDevice?.connected ?? false
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    readonly property string type: wiredConnected ? "ethernet" : wifiNetwork ? "wifi" : "disconnected"
    readonly property string name: wiredConnected ? (wiredDevice.network?.name ?? wiredDevice.name) : (wifiNetwork?.name ?? "")
    readonly property real signal: wifiNetwork?.signalStrength ?? 0
    readonly property string iface: wiredConnected ? wiredDevice.name : wifiNetwork ? wifiDevice.name : ""
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
