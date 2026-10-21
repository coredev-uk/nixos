pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light is wlsunset's schedule; toggling starts/stops its user service (stopping restores normal gamma).
Singleton {
    id: root

    property bool active: false

    function refresh() {
        query.running = true;
    }

    function toggle() {
        control.command = ["systemctl", "--user", active ? "stop" : "start", "wlsunset.service"];
        control.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: query
        command: ["systemctl", "--user", "is-active", "wlsunset.service"]
        stdout: StdioCollector {
            id: queryOut
            onStreamFinished: root.active = queryOut.text.trim() === "active"
        }
    }

    Process {
        id: control
        onExited: root.refresh()
    }
}
