import QtQuick
import qs.common
import qs.services
import qs.widgets

// The screen is being recorded (services/Recorder.qml): an alert record glyph and the time so far,
// on every bar; click stops it. Hidden otherwise. Steady: the glyph doesn't blink.
Item {
    id: root

    readonly property bool shown: Recorder.recording

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    // Stay mapped while it fades out.
    visible: shown || opacity > 0
    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    // The time gains a digit past an hour; each width is measured so the digits never shift.
    TextMetrics {
        id: cell
        font: time.font
        text: Recorder.elapsed >= 3600 ? "0:00:00" : "00:00"
    }

    Row {
        id: row
        spacing: 4

        Icon {
            text: Icons.record
            color: Theme.alert
        }

        BarText {
            id: time
            width: Math.ceil(cell.width)
            text: Recorder.elapsedText
            color: area.containsMouse ? Theme.text : Theme.text2
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Recorder.stop()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse
        text: Recorder.stopping ? "Finishing the recording…" : `Recording ${Recorder.monitor} · click to stop`
    }
}
