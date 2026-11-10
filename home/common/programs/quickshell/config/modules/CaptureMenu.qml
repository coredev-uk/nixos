import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Everything that captures the screen, under the bar's capture glyph (CaptureButton): a
// screenshot, a recording, then instant replay in a section of its own (arm it, save its end or
// all of it). Each row names its keybind on the right, so the keys can be learnt from here.
BarPopup {
    id: root

    // Closes first, so the menu isn't in the picture or the first frames of the file.
    function run(action: var) {
        visible = false;
        action();
    }

    dismissible: true
    implicitWidth: 280
    implicitHeight: frame.implicitHeight + gap

    // Long enough for the menu to have faded out before the selection freezes the screen.
    Timer {
        id: screenshot
        interval: 150
        onTriggered: Quickshell.execDetached(["quickshell-screenshot"])
    }

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: column.implicitHeight + 12

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            ListRow {
                Layout.fillWidth: true
                icon: Icons.screenshot
                label: "Screenshot an area"
                sublabel: "Print"
                onClicked: root.run(() => screenshot.start())
            }

            // Alert while recording, like its glyph in the bar: the row stops it.
            ListRow {
                Layout.fillWidth: true
                enabled: !Recorder.stopping
                icon: Recorder.recording ? Icons.stop : Icons.record
                label: Recorder.stopping ? "Finishing the file…" : Recorder.recording ? `Stop recording · ${Recorder.elapsedText}` : "Record screen"
                sublabel: "Super+Shift+R"
                active: Recorder.recording
                accent: Theme.alert
                onClicked: root.run(() => Recorder.toggle())
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Theme.rule
            }

            BarText {
                Layout.leftMargin: 12
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                text: `Instant replay · ${Replay.monitor}`
                color: Theme.text2
                font.pixelSize: 11
            }

            // On is gilt, like any service that's on; stays open so the change shows.
            ListRow {
                Layout.fillWidth: true
                icon: Icons.replay
                label: Replay.armed ? `Keeping the last ${Replay.span}` : `Keep the last ${Replay.span}`
                sublabel: !Replay.armed ? "Off" : Replay.active ? "On" : "Starting…"
                active: Replay.armed
                onClicked: Replay.toggle()
            }

            // Faded until the buffer runs, so the keys can be found before replay is on.
            ListRow {
                Layout.fillWidth: true
                enabled: Replay.armed && Replay.active
                icon: Icons.contentSave
                label: "Save the last 30 seconds"
                sublabel: "Super+Shift+C"
                onClicked: root.run(() => Replay.save(30))
            }

            ListRow {
                Layout.fillWidth: true
                enabled: Replay.armed && Replay.active
                icon: Icons.contentSave
                label: `Save all ${Replay.span}`
                sublabel: "Super+Ctrl+Shift+C"
                onClicked: root.run(() => Replay.save(0))
            }
        }
    }
}
