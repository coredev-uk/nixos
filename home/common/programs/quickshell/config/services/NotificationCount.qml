pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notification count and Do Not Disturb state for the lock screen, a separate instance from the
// bar: read from the file the bar's NotificationService publishes. Zero and off while the bar
// isn't running.
Singleton {
    id: root

    property int count: 0
    property bool dnd: false

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-notifications.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const status = JSON.parse(text());
                root.count = status.count ?? 0;
                root.dnd = status.dnd ?? false;
            } catch (e) {}
        }
    }
}
