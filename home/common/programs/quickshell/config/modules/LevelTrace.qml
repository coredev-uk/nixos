import QtQuick
import Quickshell.Services.Pipewire
import qs.common

// The player's loudness as a chart recorder's trace under now playing's lyrics: every 60ms the
// loudest PipeWire peak of the player's own stream since the last tick enters at the right edge
// as a 2px stroke rising from a 1px baseline, and the older strokes move left until they run
// out at the start. Levels are read against their own recent average, so a song mastered loud
// still moves. Quiet by role: strokes in text at 26%, the baseline in rule. Levels only, not a
// spectrum: PipeWire gives peaks, not frequencies.
Item {
    id: root

    // The player's output stream, or null.
    property PwNode node: null
    property bool running: false
    readonly property int pitch: 4
    readonly property int strokes: Math.max(1, Math.floor(width / pitch))

    // Newest last.
    property var levels: []
    property real loudest: 0
    property real average: 0

    PwObjectTracker {
        objects: root.node ? [root.node] : []
    }

    PwNodePeakMonitor {
        node: root.node
        enabled: root.running && root.node !== null
        onPeakChanged: root.loudest = Math.max(root.loudest, peak)
    }

    Timer {
        interval: 60
        repeat: true
        running: root.running && root.node !== null
        onTriggered: {
            const v = root.loudest;
            root.loudest = 0;
            // The first reading sets the average: from 0 every stroke would clip.
            root.average = root.average > 0 ? root.average + (v - root.average) * 0.06 : v;
            const level = v > 0.002 ? Math.max(0, Math.min(1, 0.35 + (v - root.average) * 4)) : 0;
            root.levels = [...root.levels.slice(-(root.strokes - 1)), level];
        }
    }

    // Silence when it stops, not a frozen trace.
    onRunningChanged: {
        if (!running) {
            levels = [];
            average = 0;
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.rule
    }

    Repeater {
        model: root.strokes

        Rectangle {
            required property int index
            // Right-aligned: the newest stroke is the last, at the right edge.
            readonly property real level: root.levels[root.levels.length - root.strokes + index] ?? 0

            x: index * root.pitch
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: 2
            height: Math.round(level * (root.height - 1))
            color: Theme.tint(Theme.text, 0.26)
        }
    }
}
