import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.common
import qs.widgets

// Per-application playback volumes (PipeWire output streams).
ColumnLayout {
    id: root

    readonly property var streams: Pipewire.nodes.values.filter(node => node.isStream && node.isSink && node.audio)

    // "PipeWire ALSA [Cider]" -> Cider, ".Discord-wrapped" -> Discord, else the app's own name.
    function appName(node: PwNode): string {
        const props = node.properties;
        const bracketed = String(props["application.name"] ?? node.description).match(/\[(.+)\]/);
        if (bracketed)
            return bracketed[1];
        const binary = String(props["application.process.binary"] ?? "").replace(/^\./, "").replace(/-wrapped$/, "");
        if (binary !== "")
            return binary.charAt(0).toUpperCase() + binary.slice(1);
        return props["application.name"] || node.description || node.name;
    }

    spacing: 0

    PwObjectTracker {
        objects: root.streams
    }

    BarText {
        visible: root.streams.length === 0
        Layout.leftMargin: 12
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        text: "No apps are playing audio"
        color: Theme.overlay0
        font.pixelSize: 11
    }

    Repeater {
        model: ScriptModel {
            values: root.streams
        }

        SliderRow {
            id: stream

            required property PwNode modelData
            readonly property string name: root.appName(modelData)
            readonly property bool muted: modelData.audio?.muted ?? false

            Layout.fillWidth: true
            label: name
            iconSource: Quickshell.iconPath(name.toLowerCase(), true)
            icon: muted ? Icons.volumeOff : Icons.volumeHigh
            color: muted ? Theme.overlay0 : Theme.lavender
            value: (modelData.audio?.volume ?? 0) * 100
            opacity: muted ? 0.6 : 1
            onMoved: value => {
                if (modelData.audio)
                    modelData.audio.volume = value / 100;
            }
            onIconClicked: {
                if (modelData.audio)
                    modelData.audio.muted = !modelData.audio.muted;
            }
        }
    }
}
