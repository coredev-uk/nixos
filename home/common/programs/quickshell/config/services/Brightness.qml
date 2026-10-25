pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Monitor brightness through set-brightness-all, which scales the dimmer monitor and reports the
// unscaled setting. DDC/CI monitors have no change notifications, so the value is read at startup
// and on refresh() (the panel refreshes when it opens); changes made here are tracked locally.
Singleton {
    id: root

    property int percent: 0
    // False until the first read lands; steps taken before that are applied on top of it.
    property bool known: false
    property int pendingStep: 0

    function refresh() {
        reader.running = true;
    }

    function set(value: real) {
        percent = Math.max(0, Math.min(100, Math.round(value)));
        known = true;
        pendingStep = 0;
        apply.restart();
    }

    function step(delta: real) {
        if (known)
            set(percent + delta);
        else
            pendingStep += delta;
    }

    Component.onCompleted: refresh()

    Process {
        id: reader
        command: ["set-brightness-all", "get"]
        stdout: StdioCollector {
            id: readerOut
            onStreamFinished: {
                const value = parseInt(readerOut.text);
                // A write still on its way would be undone by the value read before it.
                if (isNaN(value) || apply.running || writer.running)
                    return;
                root.percent = value;
                root.known = true;
                if (root.pendingStep !== 0)
                    root.step(root.pendingStep);
            }
        }
    }

    // DDC/CI writes are slow: wait for dragging or key repeat to settle, and never run two at once.
    Timer {
        id: apply
        interval: 150
        onTriggered: {
            if (writer.running) {
                writer.dirty = true;
                return;
            }
            writer.command = ["set-brightness-all", String(root.percent)];
            writer.running = true;
        }
    }

    Process {
        id: writer

        property bool dirty: false

        onExited: {
            if (dirty) {
                dirty = false;
                apply.restart();
            }
        }
    }
}
