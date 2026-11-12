import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.common
import qs.services
import qs.widgets

// Now playing as a compact card under the bar's track (MediaPopup.qml), on the cover's own colour
// (CoverArt) like what's playing in the control panel. Top: the cover, the title and artist, and on
// Sona while it plays its favourite heart. Then, on Sona, the timed lyrics (or one line saying why
// there are none). At the foot one row does the playing: previous, play/pause and next, the song as
// a track drawn like the day arc (a press or drag seeks), and the time. Clicking the cover brings
// the player's window forward. The colour moves to the next cover's over a spatial move, the title
// and artist fade in on a new track, and the play glyph grows into place on a state change.
Rectangle {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property string track: `${player?.trackTitle ?? ""}\n${player?.trackArtist ?? ""}`
    // Whether the card is on screen: the position, the lyrics, the cover's colour and Sona's
    // favourite are read only then.
    property bool active: false
    property bool watching: false

    signal playerFocused

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    implicitWidth: 400
    implicitHeight: column.implicitHeight + 24
    radius: Theme.radiusPlate
    color: art.shade
    border.color: Theme.rule
    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationMove
            easing.type: Theme.easing
        }
    }

    onTrackChanged: textFade.restart()
    onPlayingChanged: pop.restart()
    onActiveChanged: {
        if (active !== watching) {
            watching = active;
            Favourite.watch(active);
        }
    }
    Component.onDestruction: {
        if (watching)
            Favourite.watch(false);
    }

    // The lyrics are read only while the card is out.
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

    ColumnLayout {
        id: column
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            CoverArt {
                id: art
                implicitWidth: 56
                implicitHeight: 56
                ground: Theme.plate
                glyphSize: 22
                source: root.player?.trackArtUrl ?? ""
                shown: root.active
                onClicked: {
                    Media.focusPlayer();
                    root.playerFocused();
                }
            }

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

            // Sona's favourite (services/Favourite): gilt and filled when it is one, an outline
            // otherwise; only while Sona plays, once it has said which. It fills with a small beat.
            TransportButton {
                id: heart
                Layout.alignment: Qt.AlignTop
                visible: Favourite.sona && root.playing && Favourite.liked !== null
                icon: Favourite.liked ? Icons.heart : Icons.heartOutline
                on: Favourite.liked === true
                onClicked: {
                    if (!Favourite.liked)
                        beat.restart();
                    Favourite.toggle();
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

        // Three lines (the one gone, the one sung, the one coming) while Sona has timed lyrics; one
        // line saying why while it hasn't; nothing for other players.
        LyricsView {
            id: lyrics
            visible: Lyrics.sona
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.preferredHeight: ready ? lineHeight * 3 : lineHeight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
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
            }

            TransportButton {
                icon: Icons.next
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }

            SongRail {
                id: rail
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                visible: root.length > 0
                active: root.active
                player: root.player
                ground: root.color
            }

            // A live stream has no length: the controls keep their place.
            Item {
                visible: root.length <= 0
                Layout.fillWidth: true
            }

            // While dragging along the track, where it would go; in a cell as wide as the widest
            // time, so nothing shifts as the digits turn.
            BarText {
                visible: root.length > 0
                Layout.preferredWidth: widest.advanceWidth
                horizontalAlignment: Text.AlignRight
                text: `${root.clock(rail.dragging ? rail.dragSeconds : root.player?.position ?? 0)} / ${root.clock(root.length)}`
                color: Theme.text2
                font.pixelSize: 11

                TextMetrics {
                    id: widest
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.features: Theme.fontFeatures
                    // Tabular figures: the position never needs more digits than the length.
                    text: `${root.clock(root.length)} / ${root.clock(root.length)}`
                }
            }
        }
    }
}
