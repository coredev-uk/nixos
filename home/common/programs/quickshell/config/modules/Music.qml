import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Current track while playing; clicking opens its media card underneath. The track stays while
// the card is open, so pausing from it doesn't pull the bar item away. While Sona sings a timed
// line (services/Lyrics.qml) the line takes the track's place, and the track comes back while the
// voice rests. The text column keeps one width for the whole song, wide enough for its longest
// line, so the artwork never moves as lines come and go.
Item {
    id: root

    readonly property var player: Media.player
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(part => part).join(" - ")
    readonly property real maxWidth: 600
    readonly property real laneWidth: Math.min(maxWidth, Math.ceil(Math.max(metrics.advanceWidth(track), ...Lyrics.lines.map(line => metrics.advanceWidth(line)))))
    readonly property color legend: popup.visible ? Theme.gilt : Theme.text

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
            visible: (root.player?.trackArtUrl ?? "") !== ""
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

            ScrollingText {
                id: title
                width: Math.min(implicitWidth, parent.width)
                height: parent.height
                text: root.track
                // An overflowing title stops scrolling while a line covers it.
                visible: opacity > 0
                color: root.legend
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

    BarPopup {
        id: popup

        anchorItem: root
        implicitWidth: 320
        implicitHeight: frame.implicitHeight + gap
        dismissible: true

        Plate {
            id: frame
            anchors.fill: parent
            anchors.topMargin: popup.topInset
            anchors.bottomMargin: popup.bottomInset
            implicitHeight: card.implicitHeight + 24

            MediaCard {
                id: card
                anchors.fill: parent
                anchors.margins: 12
                onPlayerFocused: popup.visible = false
            }
        }
    }
}
