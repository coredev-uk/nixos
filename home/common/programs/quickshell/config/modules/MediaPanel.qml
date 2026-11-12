import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.common
import qs.services
import qs.widgets

// What's playing, at the foot of the control panel: the cover, the track, its controls, the time
// so far and, on Sona, the favourite heart, with the song as a track along the card's floor (a
// click seeks). The card takes the cover's colour (CoverArt) and moves to the next cover's over a
// spatial move; the title and artist fade in on a new track, and the play glyph grows into place
// whenever playback starts or stops, whatever started it.
Rectangle {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property string track: `${player?.trackTitle ?? ""}\n${player?.trackArtist ?? ""}`
    // Whether the panel is open: the position runs, the cover can be read and Sona is asked about
    // its favourite, only then.
    property bool shown: false
    property bool watching: false

    signal playerFocused

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    implicitHeight: 10 + 72 + 10 + 2 + 8
    radius: Theme.radiusInset
    color: art.shade

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationMove
            easing.type: Theme.easing
        }
    }

    onTrackChanged: textFade.restart()
    onPlayingChanged: pop.restart()
    onShownChanged: {
        if (shown !== watching) {
            watching = shown;
            Favourite.watch(shown);
        }
    }
    Component.onDestruction: {
        if (watching)
            Favourite.watch(false);
    }

    // MPRIS sends the position on seeks only; Quickshell works it out from the time since, when
    // asked.
    Timer {
        interval: 500
        repeat: true
        running: root.shown && root.playing
        onTriggered: root.player.positionChanged()
    }

    RowLayout {
        x: 10
        y: 10
        width: parent.width - 20
        height: 72
        spacing: 12

        CoverArt {
            id: art
            implicitWidth: 72
            implicitHeight: 72
            source: root.player?.trackArtUrl ?? ""
            shown: root.shown
            onClicked: {
                Media.focusPlayer();
                root.playerFocused();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                id: words
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
                    color: Theme.text2
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                NumberAnimation {
                    id: textFade
                    target: words
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                TransportButton {
                    icon: Icons.previous
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                TransportButton {
                    id: playPause
                    icon: root.playing ? Icons.pause : Icons.play
                    on: root.playing
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                TransportButton {
                    icon: Icons.next
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                BarText {
                    visible: root.length > 0
                    text: `${root.clock(root.player?.position ?? 0)} / ${root.clock(root.length)}`
                    color: Theme.text2
                    font.pixelSize: 11
                }

                // Sona's favourite (services/Favourite): gilt and filled when it is one ("on"), an
                // outline otherwise; only while Sona is the player and playing, and once it has said
                // which. The heart fills with a small beat.
                TransportButton {
                    id: heart
                    Layout.leftMargin: 4
                    visible: Favourite.sona && root.playing && Favourite.liked !== null
                    icon: Favourite.liked ? Icons.heart : Icons.heartOutline
                    on: Favourite.liked === true
                    onClicked: {
                        if (!Favourite.liked)
                            beat.restart();
                        Favourite.toggle();
                    }
                }
            }

            NumberAnimation {
                id: beat
                target: heart.glyph
                property: "scale"
                from: 0.7
                to: 1
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }
    }

    // The new symbol grows into place; nothing overshoots.
    NumberAnimation {
        id: pop
        target: playPause.glyph
        property: "scale"
        from: 0.6
        to: 1
        duration: Theme.durationState
        easing.type: Theme.easing
    }

    // The song along the floor, drawn like the day arc: what has played lit in text at 42%.
    Item {
        id: rail

        readonly property real progress: root.length > 0 ? Math.min(Math.max((root.player?.position ?? 0) / root.length, 0), 1) : 0

        x: 10
        y: parent.height - 8 - height
        width: parent.width - 20
        height: 2
        visible: root.length > 0

        Rectangle {
            anchors.fill: parent
            radius: 1
            color: Theme.tint(Theme.text, 0.14)
        }

        Rectangle {
            width: Math.round(rail.progress * rail.width)
            height: parent.height
            radius: 1
            color: Theme.tint(Theme.text, seekArea.containsMouse ? 0.7 : 0.42)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }

        // Taller than the track, so it is easy to hit.
        MouseArea {
            id: seekArea
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 12
            enabled: root.player?.canSeek ?? false
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => root.player.position = mouse.x / width * root.length
        }
    }
}
