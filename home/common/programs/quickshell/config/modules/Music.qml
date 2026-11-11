import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Current track while playing; clicking opens its media card underneath. The track stays while
// the card is open, so pausing from it doesn't pull the bar item away. While Sona sings a timed
// line (services/Lyrics.qml) the line takes the track's place, and the track comes back while the
// voice rests, in text2: a legend beside the reading. Hovering a line names the track. The text
// column keeps one width for the whole song, wide enough for its longest line, so the artwork
// never moves as lines come and go; at a song change it glides once to the new song's width.
Item {
    id: root

    readonly property var player: Media.player
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(part => part).join(" - ")
    // The widest the text column may be: Bar.qml narrows it to stop short of the right cluster.
    property real maxWidth: 600
    readonly property real fitWidth: Math.min(maxWidth, Math.ceil(Math.max(metrics.advanceWidth(track), ...Lyrics.lines.map(line => metrics.advanceWidth(line.text)))))
    // fitWidth, taken only once the song's lyrics are known, so a song change moves the artwork
    // once instead of first to the title's width and then to the longest line's. Sona's MPRIS
    // metadata can move on before its lyrics do; until both name the same song the lane holds,
    // for at most `hold`'s interval, so a mismatch never pins it.
    property real laneWidth: 0
    readonly property bool lyricsMatch: Lyrics.title === (player?.trackTitle ?? "")
    readonly property bool known: !Lyrics.wanted || !Lyrics.following || (Lyrics.settled && lyricsMatch)
    readonly property bool sings: lyricsMatch && Lyrics.lines.some(line => line.text !== "")
    readonly property color legend: popup.visible ? Theme.gilt : Theme.text

    function takeWidth() {
        if (known || laneWidth === 0) {
            hold.stop();
            laneWidth = fitWidth;
        } else if (!hold.running) {
            hold.start();
        }
    }
    onFitWidthChanged: takeWidth()
    onKnownChanged: takeWidth()
    Component.onCompleted: takeWidth()

    Timer {
        id: hold
        interval: 2000
        onTriggered: root.laneWidth = root.fitWidth
    }

    Behavior on laneWidth {
        enabled: root.visible
        NumberAnimation {
            duration: Theme.durationMove
            easing.type: Theme.easing
        }
    }

    // The line on screen, and the one waiting for it: the old line leaves before the new one
    // arrives, so two never overlap.
    property string shown: ""
    property string pending: ""
    property bool leaving: false

    function swapLine() {
        if (Lyrics.line === pending && !leaving)
            return;
        pending = Lyrics.line;
        leaving = true;
        settle.restart();
    }

    Connections {
        target: Lyrics
        function onLineChanged() {
            root.swapLine();
        }
    }

    Timer {
        id: settle
        interval: Theme.durationExit
        onTriggered: {
            root.shown = root.pending;
            root.leaving = false;
        }
    }

    FontMetrics {
        id: metrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.features: Theme.fontFeatures
    }

    visible: (player?.isPlaying ?? false) || popup.visible
    onPlayerChanged: {
        if (!player)
            popup.visible = false;
    }
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        ClippingRectangle {
            // The well stays while a player has no artwork yet (Sona fills it in after the
            // title at a song change), so the text never shifts by the artwork's width.
            implicitWidth: 20
            implicitHeight: 20
            radius: 4
            color: Theme.inset

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: 40
                sourceSize.height: 40
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Item {
            Layout.preferredWidth: root.laneWidth
            implicitHeight: title.implicitHeight
            clip: true

            ScrollingText {
                id: title
                width: Math.min(implicitWidth, parent.width)
                height: parent.height
                text: root.track
                // An overflowing title stops scrolling while a line covers it.
                visible: opacity > 0
                color: popup.visible ? Theme.gilt : root.sings ? Theme.text2 : Theme.text
                opacity: !root.leaving && root.shown === "" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.leaving ? Theme.durationExit : Theme.durationState
                        easing.type: root.leaving ? Theme.easingExit : Theme.easing
                    }
                }
            }

            BarText {
                anchors.fill: parent
                text: root.shown
                color: root.legend
                elide: Text.ElideRight
                opacity: !root.leaving && root.shown !== "" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.leaving ? Theme.durationExit : Theme.durationState
                        easing.type: root.leaving ? Theme.easingExit : Theme.easing
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    // Names the song while a line stands in for it.
    Tooltip {
        anchorItem: root
        active: area.containsMouse && !popup.visible && root.shown !== ""
        text: root.track
    }

    // The media card, and under it the song's lyrics while Sona has timed ones (LyricsView); the
    // popup widens to 420px for them and snaps back to 320px without.
    BarPopup {
        id: popup

        anchorItem: root
        implicitWidth: lyrics.shown ? 420 : 320
        implicitHeight: frame.implicitHeight + gap
        dismissible: true

        Plate {
            id: frame
            anchors.fill: parent
            anchors.topMargin: popup.topInset
            anchors.bottomMargin: popup.bottomInset
            implicitHeight: content.implicitHeight + 24

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                MediaCard {
                    width: parent.width
                    onPlayerFocused: popup.visible = false
                }

                LyricsView {
                    id: lyrics
                    width: parent.width
                    visible: shown
                    active: popup.visible
                }
            }
        }
    }
}
