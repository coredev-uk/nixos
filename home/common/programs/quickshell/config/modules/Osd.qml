import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// On-screen display for the volume, microphone, brightness and media keys, driven over IPC
// (`quickshell ipc -c bar call osd <function> <arg>`, see keybindings.nix) so it only appears for
// key presses, not when the panel or an app changes a value. A card above the bottom edge of the
// focused monitor that hides shortly after the last press.
Scope {
    id: root

    // "volume", "mic", "brightness" or "media".
    property string kind: ""
    property bool shown: false
    // Keeps the window around while it fades out.
    property bool loaded: false
    property string screenName: ""
    // The player the last media key went to.
    property MprisPlayer player: null

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    // Also brings the service up at startup, so the first key press already knows the brightness.
    readonly property int brightness: Brightness.percent

    function show(newKind: string) {
        kind = newKind;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        shown = true;
        loaded = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    IpcHandler {
        target: "osd"

        // Steps the default output by `step` percent ("+5", "-5"); raising also unmutes.
        function volume(step: string): void {
            const audio = root.sink?.audio;
            const delta = parseFloat(step);
            if (!audio || isNaN(delta))
                return;
            audio.volume = Math.max(0, Math.min(100, Math.round(audio.volume * 100 + delta))) / 100;
            if (delta > 0)
                audio.muted = false;
            root.show("volume");
        }

        function mute(): void {
            const audio = root.sink?.audio;
            if (!audio)
                return;
            audio.muted = !audio.muted;
            root.show("volume");
        }

        function micMute(): void {
            const audio = root.source?.audio;
            if (!audio)
                return;
            audio.muted = !audio.muted;
            root.show("mic");
        }

        // Steps the monitors by `step` percent ("+10", "-10").
        function brightness(step: string): void {
            const delta = parseFloat(step);
            if (isNaN(delta))
                return;
            Brightness.step(delta);
            root.show("brightness");
        }

        // "play-pause", "next" or "previous" on the player the bar follows, else any player.
        function media(action: string): void {
            const player = Media.player ?? Mpris.players.values[0] ?? null;
            if (!player)
                return;
            if (action === "play-pause")
                player.togglePlaying();
            else if (action === "next")
                player.next();
            else if (action === "previous")
                player.previous();
            else
                return;
            root.player = player;
            root.show("media");
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    // Unloads once the fade-out has finished.
    Timer {
        running: !root.shown && root.loaded
        interval: 250
        onTriggered: root.loaded = false
    }

    LazyLoader {
        active: root.loaded

        PanelWindow {
            id: window

            // Room around the card for its shadow.
            readonly property int shadowPadding: 24

            screen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]
            anchors.bottom: true
            margins.bottom: 100 - shadowPadding
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: card.width + shadowPadding * 2
            implicitHeight: card.height + shadowPadding * 2
            color: "transparent"
            // Purely informational: clicks go through and focus stays where it was.
            mask: Region {}
            WlrLayershell.namespace: "osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                id: card

                // Rises into place as it fades in, sinks as it fades out.
                property real drop: 8

                width: 300
                height: content.implicitHeight + 24
                anchors.horizontalCenter: parent.horizontalCenter
                y: window.shadowPadding + drop
                opacity: 0
                radius: 12
                color: Theme.mantle
                border.width: 1
                border.color: Theme.surface0

                // Fade in on creation too; later shows reuse the window if it hasn't unloaded yet.
                Component.onCompleted: {
                    opacity = Qt.binding(() => root.shown ? 1 : 0);
                    drop = Qt.binding(() => root.shown ? 0 : 8);
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowOpacity: 0.35
                    shadowBlur: 1
                    shadowVerticalOffset: 6
                }

                Item {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 12
                    implicitHeight: root.kind === "media" ? mediaRow.implicitHeight : levelRow.implicitHeight

                    LevelRow {
                        id: levelRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.kind !== "media"
                    }

                    MediaRow {
                        id: mediaRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.kind === "media"
                    }
                }
            }
        }
    }

    // Icon, then a bar and percentage (volume, brightness) or a label (microphone).
    component LevelRow: RowLayout {
        id: level

        readonly property bool muted: root.kind === "volume" ? root.sink?.audio?.muted ?? false : root.kind === "mic" ? root.source?.audio?.muted ?? false : false
        readonly property real value: root.kind === "volume" ? (root.sink?.audio?.volume ?? 0) * 100 : root.brightness
        readonly property color accent: muted ? Theme.overlay0 : root.kind === "brightness" ? Theme.yellow : Theme.blue

        spacing: 10

        Icon {
            Layout.preferredWidth: 24
            text: {
                if (root.kind === "brightness")
                    return Icons.brightness;
                if (root.kind === "mic")
                    return level.muted ? Icons.microphoneOff : Icons.microphone;
                if (level.muted)
                    return Icons.volumeOff;
                return level.value > 66 ? Icons.volumeHigh : level.value > 33 ? Icons.volumeMedium : Icons.volumeLow;
            }
            color: level.accent
            font.pixelSize: 20
        }

        Rectangle {
            visible: root.kind !== "mic"
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.surface0

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, level.value / 100))
                height: parent.height
                radius: parent.radius
                color: level.accent

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        BarText {
            visible: root.kind !== "mic"
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(level.value)}%`
            color: level.muted ? Theme.overlay0 : Theme.subtext0
            font.pixelSize: 12
        }

        BarText {
            visible: root.kind === "mic"
            Layout.fillWidth: true
            text: level.muted ? "Microphone muted" : "Microphone on"
            color: level.muted ? Theme.subtext0 : Theme.text
            font.pixelSize: 12
        }
    }

    // Artwork (or a music glyph), title and artist, and whether it's now playing or paused.
    component MediaRow: RowLayout {
        spacing: 10

        ClippingRectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: 6
            color: Theme.surface0

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: Icons.music
                color: Theme.subtext0
            }

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: 80
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            BarText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown track"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            BarText {
                Layout.fillWidth: true
                text: root.player?.trackArtist || "Unknown artist"
                color: Theme.subtext0
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Icon {
            Layout.preferredWidth: 24
            text: root.player?.isPlaying ? Icons.play : Icons.pause
            color: Theme.pink
            font.pixelSize: 20
        }
    }
}
