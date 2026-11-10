pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether the bar is recording the screen (services/Recorder.qml), for the lock screen, a separate
// instance from the bar: read from the file the bar publishes. Not recording while the bar isn't
// running; a bar that died mid-recording leaves it set, which keeps the lock's day redacted.
Singleton {
    id: root

    property bool recording: false

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-recording.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.recording = JSON.parse(text()).recording ?? false;
            } catch (e) {}
        }
    }
}
