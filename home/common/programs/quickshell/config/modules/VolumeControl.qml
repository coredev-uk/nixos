import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.common
import qs.widgets

// Default sink volume (the icon toggles mute); the chevron expands per-app volumes underneath.
ColumnLayout {
    id: root

    property bool expanded: false

    signal expandToggled

    readonly property PwNode sink: Pipewire.defaultAudioSink

    spacing: 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    SliderRow {
        id: master

        readonly property bool muted: root.sink?.audio?.muted ?? false

        Layout.fillWidth: true
        value: (root.sink?.audio?.volume ?? 0) * 100
        icon: muted ? Icons.volumeOff : value > 66 ? Icons.volumeHigh : value > 33 ? Icons.volumeMedium : Icons.volumeLow
        color: muted ? Theme.overlay0 : Theme.blue
        expandable: true
        expanded: root.expanded
        onExpandToggled: root.expandToggled()
        onMoved: value => {
            if (root.sink?.audio)
                root.sink.audio.volume = value / 100;
        }
        onIconClicked: {
            if (root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    Rectangle {
        visible: root.expanded
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        implicitHeight: mixer.implicitHeight + 8
        radius: 8
        color: Theme.base

        AudioMixer {
            id: mixer
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
        }
    }
}
