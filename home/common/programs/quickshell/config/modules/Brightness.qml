import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.widgets

// DDC/CI monitors have no change notifications, so brightness is read when the slider is revealed.
RowLayout {
    id: root

    property real brightness: 0

    spacing: 10

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered)
                reader.running = true;
        }
    }

    Icon {
        text: Icons.brightness
        color: Theme.yellow
    }

    Item {
        Layout.preferredWidth: hover.hovered ? slider.implicitWidth : 0
        implicitHeight: slider.implicitHeight
        clip: true

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        BarSlider {
            id: slider
            value: root.brightness
            color: Theme.yellow
            onMoved: value => {
                root.brightness = value;
                apply.restart();
            }
        }
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            id: readerOut
            onStreamFinished: {
                const percent = parseInt(readerOut.text.split("\n")[0].split(",")[3]);
                if (!isNaN(percent))
                    root.brightness = percent;
            }
        }
    }

    // DDC/CI writes are slow; only apply once dragging settles.
    Timer {
        id: apply
        interval: 150
        onTriggered: Quickshell.execDetached(["set-brightness-all", String(Math.round(root.brightness))])
    }
}
