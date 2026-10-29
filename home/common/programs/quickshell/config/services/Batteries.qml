pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Peripheral batteries (OpenRazer + HeadsetControl) via the quickshell-batteries helper.
// Reading the headset is a HID round trip of ~1.5 s, so the background check that feeds the
// bar's low-battery glyph runs every 5 minutes; each visible panel (one per screen) holds a
// reference through acquire()/release() and reads every minute while open.
Singleton {
    id: root

    // [{ name, short, kind, level (0-100 | null), charging }]
    property var devices: []
    property int users: 0
    readonly property bool active: users > 0
    // At or below the bar's threshold and not charging; a switched-off headset reports no level.
    readonly property int lowLevel: 15
    readonly property var low: devices.filter(device => device.level !== null && device.level <= lowLevel && !device.charging)

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
    Component.onCompleted: refresh()

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
        interval: root.active ? 60000 : 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
