pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Peripheral batteries (OpenRazer + HeadsetControl) via the quickshell-batteries helper.
// Polled only while a panel shows them: reading the headset is a HID round trip of
// ~1.5 s, so it shouldn't run in the background. Each visible panel (one per screen)
// holds a reference through acquire()/release().
Singleton {
    id: root

    // [{ name, short, kind, level (0-100 | null), charging }]
    property var devices: []
    property int users: 0
    readonly property bool active: users > 0

    function acquire() {
        users++;
    }

    function release() {
        users = Math.max(0, users - 1);
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    onActiveChanged: {
        if (active)
            refresh();
    }

    Process {
        id: proc
        command: ["quickshell-batteries"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(out.text);
                } catch (e) {
                    root.devices = [];
                }
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }
}
