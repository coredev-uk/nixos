pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notification count and Do Not Disturb state pushed by swaync.
Singleton {
    id: root

    property int count: 0
    property bool dnd: false

    Process {
        id: subscription
        command: ["swaync-client", "--subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const state = JSON.parse(line);
                    root.count = state.count ?? 0;
                    root.dnd = state.dnd ?? false;
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
