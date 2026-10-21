pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notification count pushed by swaync.
Singleton {
    id: root

    property int count: 0

    Process {
        id: subscription
        command: ["swaync-client", "--subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.count = JSON.parse(line).count ?? 0;
                } catch (e) {}
            }
        }
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: subscription.running = true
    }
}
