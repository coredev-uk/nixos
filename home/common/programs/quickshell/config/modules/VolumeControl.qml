import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.common
import qs.services
import qs.widgets

// Default output's volume, named under the track (the icon toggles mute). The chevron, or the
// name, opens the outputs (this computer's and AirPlay speakers) and per-app volumes underneath.
ColumnLayout {
    id: root

    property bool expanded: false
    // Whether the containing panel is open; AirPlay speakers are only polled while listed.
    property bool shown: false
    property bool watching: false

    signal expandToggled

    readonly property PwNode sink: Pipewire.defaultAudioSink
    // AirPlay's sink feeds OwnTone, whose speakers are listed separately.
    readonly property var localOutputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio && node !== AirPlay.sink).sort((a, b) => outputName(a).localeCompare(outputName(b)))

    // GNOME Network Displays leaves its sink behind; picking it sends audio along with a screen cast.
    function isScreenCast(node: PwNode): bool {
        return node.name.startsWith("gnome_network_displays");
    }

    function outputName(node: PwNode): string {
        if (isScreenCast(node))
            return "Screen cast";
        return node.description || node.nickname || node.name;
    }

    function sync() {
        const watch = shown && expanded;
        if (watch === watching)
            return;
        watching = watch;
        AirPlay.watch(watch);
    }

    spacing: 0

    // The size snaps (the panel is a popup); the list's content eases in.
    onExpandedChanged: {
        sync();
        if (expanded)
            listFade.restart();
    }
    onShownChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: {
        if (watching)
            AirPlay.watch(false);
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    SliderRow {
        id: master

        readonly property bool muted: root.sink?.audio?.muted ?? false

        Layout.fillWidth: true
        value: (root.sink?.audio?.volume ?? 0) * 100
        icon: muted ? Icons.volumeOff : value > 66 ? Icons.volumeHigh : value > 33 ? Icons.volumeMedium : Icons.volumeLow
        color: muted ? Theme.muted : Theme.fill
        iconColor: muted ? Theme.muted : Theme.text2
        valueText: muted ? "Muted" : `${Math.round(value)}%`
        sublabel: {
            if (!root.sink)
                return "No output";
            if (AirPlay.casting)
                return AirPlay.chosen.length > 0 ? `AirPlay - ${AirPlay.chosen.map(speaker => speaker.name).join(", ")}` : "AirPlay";
            return root.outputName(root.sink);
        }
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
        Layout.topMargin: 2
        Layout.bottomMargin: 4
        implicitHeight: list.implicitHeight + 8
        radius: Theme.radiusInset
        color: Theme.inset

        NumberAnimation {
            id: listFade
            target: list
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.durationState
            easing.type: Theme.easing
        }

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            SectionLabel {
                Layout.topMargin: 4
                text: "This computer"
            }

            Repeater {
                model: ScriptModel {
                    values: root.localOutputs
                }

                ListRow {
                    required property PwNode modelData
                    readonly property bool screenCast: root.isScreenCast(modelData)

                    Layout.fillWidth: true
                    icon: screenCast ? Icons.monitorShare : Icons.speaker
                    label: root.outputName(modelData)
                    sublabel: screenCast ? "With Cast screen" : ""
                    active: modelData === root.sink
                    onClicked: {
                        if (AirPlay.casting)
                            AirPlay.select([]);
                        AirPlay.playOn(modelData);
                    }
                }
            }

            SectionLabel {
                Layout.topMargin: 6
                text: "AirPlay"
            }

            // Several can play at once (multi-room); they play about a second late, so it suits music.
            Repeater {
                model: ScriptModel {
                    values: AirPlay.speakers
                    objectProp: "id"
                }

                ListRow {
                    required property var modelData

                    Layout.fillWidth: true
                    icon: Icons.speakerWireless
                    label: modelData.name
                    sublabel: modelData.failed ? "Couldn't connect" : modelData.chosen ? (AirPlay.casting ? "Playing" : "Selected") : ""
                    active: modelData.chosen && AirPlay.casting
                    onClicked: AirPlay.toggleSpeaker(modelData)
                }
            }

            // The first connection to a TV shows a code on its screen.
            Repeater {
                model: ScriptModel {
                    values: AirPlay.speakers.filter(speaker => speaker.needsPin)
                    objectProp: "id"
                }

                PasswordField {
                    required property var modelData

                    Layout.fillWidth: true
                    title: `Code shown on ${modelData.name}, if any`
                    onSubmitted: pin => AirPlay.submitPin(modelData, pin)
                    onCancelled: AirPlay.dismissPin(modelData)
                }
            }

            BarText {
                visible: text !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: {
                    if (!AirPlay.known)
                        return "Looking for speakers…";
                    if (!AirPlay.available)
                        return "AirPlay isn't running (the owntone user service)";
                    if (AirPlay.error !== "")
                        return AirPlay.error;
                    return AirPlay.speakers.length === 0 ? "No AirPlay speakers found on the network" : "";
                }
                color: AirPlay.known && (!AirPlay.available || AirPlay.error !== "") ? Theme.alert : Theme.text2
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            SectionLabel {
                Layout.topMargin: 6
                text: "Apps"
            }

            AudioMixer {
                Layout.fillWidth: true
            }
        }
    }
}
