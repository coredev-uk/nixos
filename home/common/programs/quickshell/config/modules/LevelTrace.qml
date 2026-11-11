import QtQuick
import Quickshell.Services.Pipewire
import qs.common

// The player's loudness as a chart recorder's trace under now playing's lyrics: every 60ms the
// loudest PipeWire peak of the player's own stream since the last tick enters at the right edge
// as a 2px stroke rising from a 1px baseline, and the older strokes move left until they run
// out at the start. Quiet by role: strokes in text at 30%, the baseline in rule. Levels only,
// not a spectrum: PipeWire gives peaks, not frequencies.
//
// Scaling: mastered music barely moves in absolute terms (Sona's stream measured on atlas: the
// 60ms peaks of a whole verse within about 2 dB, -12.3 to -10.3 dBFS), so a fixed or linear
// scale draws a flat line. Each reading is taken in dB and placed in the song's own recent
// range: `ceil` jumps up to a louder reading and sinks 0.02 dB a tick (0.33 dB/s) after it,
// `floor` the same the other way, and the trace spans the window between them, centred on
// their middle and never narrower than 1.5 dB, so the loudest moments of the last few seconds
// reach the top whatever the mastering. Measured on the same verse: strokes from 12% (p10) to
// full height (p90), median 72%.
Item {
    id: root

    // The player's output stream, or null.
    property PwNode node: null
    property bool running: false
    readonly property int pitch: 4
    readonly property int strokes: Math.max(1, Math.floor(width / pitch))
    readonly property real minSpan: 1.5
    readonly property real release: 0.02

    // Newest last.
    property var levels: []
    property real loudest: 0
    // The recent range in dBFS; NaN until the first reading.
    property real ceil: NaN
    property real floor: NaN

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
            let level = 0;
            // Below -60 dBFS is silence (a pause, the gap between songs): no stroke, and the
            // range is left as it was.
            if (v > 0.001) {
                const db = 20 * Math.log10(v);
                if (isNaN(root.ceil)) {
                    root.ceil = db + root.minSpan / 2;
                    root.floor = db - root.minSpan / 2;
                }
                root.ceil = Math.max(db, root.ceil - root.release);
                root.floor = Math.min(db, root.floor + root.release);
                const span = Math.max(root.minSpan, root.ceil - root.floor);
                const low = (root.ceil + root.floor) / 2 - span / 2;
                level = Math.max(0, Math.min(1, (db - low) / span));
            }
            root.levels = [...root.levels.slice(-(root.strokes - 1)), level];
        }
    }

    // Silence when it stops, not a frozen trace; the range starts again from the next reading.
    onRunningChanged: {
        if (!running) {
            levels = [];
            ceil = NaN;
            floor = NaN;
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
            // A reading at the bottom of the range still draws a pixel; only silence draws none.
            height: level > 0 ? Math.max(1, Math.round(level * (root.height - 1))) : 0
            color: Theme.tint(Theme.text, 0.3)
        }
    }
}
