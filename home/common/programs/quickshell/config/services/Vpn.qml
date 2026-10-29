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
    // The running helper action ("connect" or "disconnect", "" when idle) and the country it
    // connects to ("" for the fastest server). Kept after it ends, for the failure line.
    property string action: ""
    property string target: ""
    property bool busy: false
    property bool failed: false
    readonly property bool connecting: busy && action === "connect"
    readonly property bool disconnecting: busy && action === "disconnect"
    // Why the last action failed, in plain words; the helper prints protonvpn's reason on stderr.
    readonly property string error: failed ? reason(action, target, actionErr.text) : ""
    // Exit country of the server: UK for UK#12, and the second code for Secure Core's CH-UK#1.
    readonly property string country: {
        const match = /^([A-Z]{2})(?:-([A-Z]{2}))?#/.exec(server);
        if (match)
            return match[2] ?? match[1];
        return connected && action === "connect" && !failed ? target : "";
    }

    function refresh() {
        statusProc.running = true;
    }

    function loadCountries() {
        countriesProc.running = true;
    }

    function run(newAction: string, country: string, command: var) {
        if (busy)
            return;
        action = newAction;
        target = country;
        failed = false;
        busy = true;
        actionProc.command = command;
        actionProc.running = true;
    }

    function connect(country: string) {
        run("connect", country, country === "" ? ["quickshell-vpn", "--connect"] : ["quickshell-vpn", "--connect", country]);
    }

    function disconnect() {
        run("disconnect", "", ["quickshell-vpn", "--disconnect"]);
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

    // "United Kingdom" for UK once the list has loaded, the code until then.
    function countryName(code: string): string {
        return countries.find(entry => entry.code === code)?.name ?? code;
    }

    function reason(failedAction: string, country: string, detail: string): string {
        const what = failedAction === "disconnect" ? "Couldn't disconnect" : `Couldn't connect to ${country === "" ? "the VPN" : countryName(country)}`;
        // protonvpn's last line, without colour codes or its "Error:" prefix.
        const why = detail.replace(/\x1b\[[0-9;]*m/g, "").trim().replace(/^error:\s*/i, "");
        if (why === "")
            return `${what}. Try again in a moment.`;
        if (/sign(ed)? ?in|log(ged)? ?in|credentials/i.test(why))
            return `${what}: signed out of Proton VPN (run protonvpn signin).`;
        return `${what}: ${why}`;
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
                // Notify on every transition after startup, whoever changed the connection; a
                // transition also makes an earlier failure stale.
                if (root.statusKnown && isConnected !== root.connected) {
                    Quickshell.execDetached(["quickshell-vpn", "--notify-state"]);
                    if (!root.busy)
                        root.failed = false;
                }
                root.connected = isConnected;
                root.statusKnown = true;
                root.ip = ip ?? "";
                root.server = server ?? "";
                // The bar's tooltip names the country; the list is otherwise only read for the panel.
                if (isConnected && root.countries.length === 0 && !countriesProc.running)
                    root.loadCountries();
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
        stderr: StdioCollector {
            id: actionErr
        }
        onExited: exitCode => {
            root.failed = exitCode !== 0;
            root.busy = false;
            root.refresh();
        }
    }
}
