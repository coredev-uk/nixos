import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.common
import qs.widgets

RowLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: (sink?.audio?.volume ?? 0) * 100

    spacing: 10

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    HoverHandler {
        id: hover
    }

    Icon {
        text: root.muted ? Icons.volumeOff : root.volume > 66 ? Icons.volumeHigh : root.volume > 33 ? Icons.volumeMedium : Icons.volumeLow
        color: Theme.blue

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.sink.audio.muted;
            }
        }
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
            value: root.volume
            color: Theme.blue
            onMoved: value => {
                if (root.sink?.audio)
                    root.sink.audio.volume = value / 100;
            }
        }
    }
}
