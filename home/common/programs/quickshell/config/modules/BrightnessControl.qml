import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.widgets

// DDC/CI monitors have no change notifications, so brightness is read whenever the row is created
// (each time the panel's main view opens) and written through set-brightness-all.
SliderRow {
    id: root

    icon: Icons.brightness
    color: Theme.yellow

    Component.onCompleted: reader.running = true

    onMoved: value => {
        root.value = value;
        apply.restart();
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            id: readerOut
            onStreamFinished: {
                const percent = parseInt(readerOut.text.split("\n")[0].split(",")[3]);
                if (!isNaN(percent))
                    root.value = percent;
            }
        }
    }

    // DDC/CI writes are slow; only apply once dragging settles.
    Timer {
        id: apply
        interval: 150
        onTriggered: Quickshell.execDetached(["set-brightness-all", String(Math.round(root.value))])
    }
}
