import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Now playing as a wide, short strip on a plate (MediaPopup.qml hangs it under the bar), so it
// covers as little of the window below as it can. Left to right: the artwork; the track, its
// controls and the time; the lyrics over the player's level trace. The song runs along the floor
// as a track drawn like the bar's day arc. Clicking the artwork brings the player's window
// forward.
Item {
    id: root

    readonly property var player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0
    // The player's own output stream, for the level trace.
    readonly property PwNode stream: {
        const name = root.player ? Media.clientName(root.player) : "";
        if (name === "")
            return null;
        return Pipewire.nodes.values.find(n => n.isStream && n.isSink && n.audio && [n.name, n.properties["application.name"], n.properties["application.process.binary"]].some(v => String(v ?? "").toLowerCase().includes(name))) ?? null;
    }

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // Whether the strip is on screen: the position, the lyrics and the trace run only then.
    property bool active: false

    signal playerFocused

    implicitWidth: 880
    implicitHeight: frame.implicitHeight

    // The lyrics are read only while the strip is out.
    Binding {
        target: Lyrics
        property: "watched"
        value: root.active
    }

    // MPRIS sends the position on seeks only; Quickshell works it out from the time since, when
    // asked.
    Timer {
        interval: 250
        repeat: true
        running: root.active && root.playing
        onTriggered: root.player.positionChanged()
    }

    component Control: Rectangle {
        id: control

        property alias icon: glyph.text
        // "On": the play state while playing, gilt as everything that is on.
        property bool on: false

        signal clicked

        implicitWidth: 32
        implicitHeight: 32
        radius: Theme.radiusRow
        color: on ? Theme.tint(Theme.gilt, hover.containsMouse ? 0.16 : 0.1) : hover.containsMouse ? Theme.hover : "transparent"
        opacity: enabled ? 1 : 0.5

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Icon {
            id: glyph
            anchors.centerIn: parent
            font.pixelSize: 18
            color: control.on ? Theme.gilt : hover.containsMouse ? Theme.text : Theme.text2
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }
    }

    Plate {
        id: frame
        anchors.fill: parent
        implicitHeight: 12 + row.implicitHeight + 10 + rail.implicitHeight + 8

        RowLayout {
            id: row
            x: 12
            y: 12
            width: parent.width - 24
            height: 112
            spacing: 16

            ClippingRectangle {
                implicitWidth: 112
                implicitHeight: 112
                radius: Theme.radiusInset
                color: Theme.inset

                // The artwork often arrives after the title: the glyph holds its place.
                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: Icons.music
                    color: Theme.muted
                    font.pixelSize: 32
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(224, 224)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Media.focusPlayer();
                        root.playerFocused();
                    }
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.preferredWidth: 208
                Layout.maximumWidth: 208
                Layout.fillHeight: true

                BarText {
                    text: root.player?.trackTitle || "Unknown track"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                BarText {
                    text: root.player?.trackArtist || "Unknown artist"
                    color: Theme.text2
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    Control {
                        icon: Icons.previous
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                    }

                    Control {
                        icon: root.playing ? Icons.pause : Icons.play
                        on: root.playing
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                    }

                    Control {
                        icon: Icons.next
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    BarText {
                        visible: root.length > 0
                        // While dragging along the floor, where it would go.
                        text: `${root.clock(rail.dragging ? rail.dragSeconds : root.player?.position ?? 0)} / ${root.clock(root.length)}`
                        color: Theme.text2
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                implicitWidth: 1
                Layout.fillHeight: true
                color: Theme.rule
            }

            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true
                Layout.fillHeight: true

                LyricsView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                LevelTrace {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14
                    node: root.stream
                    running: root.active && root.playing
                }
            }
        }

        SongRail {
            id: rail
            active: root.active

            x: 12
            y: row.y + row.height + 10
            width: parent.width - 24
            player: root.player
        }
    }
}
