pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ProtonVPN state via the quickshell-vpn helper; refreshed on kernel link events instead of polling.
Singleton {
    id: root

    property bool connected: false
    property bool statusKnown: false
    property string ip: ""
    property string server: ""
    property var countries: []
    readonly property bool loadingCountries: countriesProc.running

    function refresh() {
        statusProc.running = true;
    }

    function loadCountries() {
        countriesProc.running = true;
    }

    function connect(country: string) {
        actionProc.command = country === "" ? ["quickshell-vpn", "--connect"] : ["quickshell-vpn", "--connect", country];
        actionProc.running = true;
    }

    function disconnect() {
        actionProc.command = ["quickshell-vpn", "--disconnect"];
        actionProc.running = true;
    }

    function toggle() {
        if (connected)
            disconnect();
        else
            connect("");
    }

    function flag(code: string): string {
        // Regional indicator symbols; ProtonVPN uses UK instead of the ISO code GB.
        const iso = code === "UK" ? "GB" : code;
        return String.fromCodePoint(...Array.from(iso.toUpperCase(), c => 0x1F1E6 + c.charCodeAt(0) - 65));
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProc
        command: ["quickshell-vpn", "--status"]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: {
                const [connected, ip, server] = statusOut.text.replace(/\n$/, "").split("\t");
                const isConnected = connected === "true";
                // Notify on every transition after startup, whoever changed the connection.
                if (root.statusKnown && isConnected !== root.connected)
                    Quickshell.execDetached(["quickshell-vpn", "--notify-state"]);
                root.connected = isConnected;
                root.statusKnown = true;
                root.ip = ip ?? "";
                root.server = server ?? "";
            }
        }
    }

    Process {
        id: linkMonitor
        command: ["ip", "monitor", "link"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
        onExited: monitorRestart.start()
    }

    Timer {
        id: monitorRestart
        interval: 5000
        onTriggered: linkMonitor.running = true
    }

    Timer {
        id: debounce
        interval: 500
        onTriggered: root.refresh()
    }

    Process {
        id: countriesProc
        command: ["quickshell-vpn", "--countries"]
        stdout: StdioCollector {
            id: countriesOut
            onStreamFinished: {
                root.countries = countriesOut.text.split("\n").filter(line => line !== "").map(line => {
                    const [code, name] = line.split("\t");
                    return {
                        code,
                        name,
                        flag: root.flag(code)
                    };
                });
            }
        }
    }

    Process {
        id: actionProc
        onExited: root.refresh()
    }
}
