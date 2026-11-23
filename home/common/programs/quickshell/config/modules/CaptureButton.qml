import QtQuick
import qs.common
import qs.services
import qs.widgets

// Capture glyph opening CaptureMenu. Gilt while instant replay is armed; while recording, alert dot and elapsed time on every bar.
Item {
    id: root

    readonly property bool recording: Recorder.recording

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // The time gains a digit past an hour; each width is measured so digits never shift.
    TextMetrics {
        id: cell
        font: time.font
        text: Recorder.elapsed >= 3600 ? "0:00:00" : "00:00"
    }

    Row {
        id: row
        spacing: 4

        Icon {
            text: root.recording ? Icons.record : Icons.capture
            color: root.recording ? Theme.alert : menu.visible || Replay.armed ? Theme.gilt : area.containsMouse ? Theme.text2 : Theme.muted
        }

        BarText {
            id: time
            visible: root.recording
            width: Math.ceil(cell.width)
            text: Recorder.elapsedText
            color: menu.visible ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.toggle()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !menu.visible
        text: Recorder.stopping ? "Finishing the recording…" : root.recording ? `Recording ${Recorder.monitor}` : Replay.armed ? `Instant replay: keeping the last ${Replay.span} of ${Replay.monitor}` : "Screenshot, record, replay"
    }

    CaptureMenu {
        id: menu
        anchorItem: root
    }
}
