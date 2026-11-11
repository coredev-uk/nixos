import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Current track while playing; clicking opens its media card underneath. The track stays while
// the card is open, so pausing from it doesn't pull the bar item away.
//
// When Sona has timed lyrics for the song (services/Lyrics.qml), the track gives way to the
// lyrics as a tape across all the room the bar has: the line being sung centred in text, the
// lines before and after it in text2 running out to the ends, where they fade into the ground.
// Each new line glides the tape to the centre (Move), so the eye follows the song along it;
// between lines the next one waits at the centre, in text2 until it is sung. Hovering names the
// track. The widget changes width only at a song change, gliding once, when the new song's
// lyrics are known.
Item {
    id: root

    readonly property var player: Media.player
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(part => part).join(" - ")
    // The room for the text column; Bar.qml stops it short of the right cluster.
    property real maxWidth: 600
    // Sona's MPRIS metadata can move on before its lyrics do; until both name the same song the
    // width holds, for at most `hold`'s interval, so a mismatch never pins it.
    readonly property bool lyricsMatch: Lyrics.title === (player?.trackTitle ?? "")
    readonly property bool known: !Lyrics.wanted || !Lyrics.following || (Lyrics.settled && lyricsMatch)
    readonly property bool tapeMode: lyricsMatch && Lyrics.lines.some(line => line.text !== "")
    readonly property real fitWidth: tapeMode ? maxWidth : Math.min(600, maxWidth, Math.ceil(metrics.advanceWidth(track)))
    property real laneWidth: 0
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

    // A new song's tape is placed, not glided: its lines arrive all at once.
    property bool glide: false

    Connections {
        target: Lyrics
        function onLinesChanged() {
            root.glide = false;
            glideOn.restart();
        }
    }

    Timer {
        id: glideOn
        interval: 100
        onTriggered: root.glide = true
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
                // An overflowing title stops scrolling while the tape covers it.
                visible: opacity > 0
                color: root.legend
                opacity: root.tapeMode ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }

            Item {
                id: strip
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.tapeMode ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                Row {
                    id: tape

                    readonly property Item focusItem: lineItems.count > 0 && Lyrics.focus >= 0 ? lineItems.itemAt(Lyrics.focus) : null

                    height: parent.height
                    x: focusItem ? Math.round(strip.width / 2 - focusItem.x - focusItem.width / 2) : 0

                    Behavior on x {
                        enabled: root.glide && root.visible
                        NumberAnimation {
                            duration: Theme.durationMove
                            easing.type: Theme.easing
                        }
                    }

                    Repeater {
                        id: lineItems
                        model: Lyrics.lines

                        BarText {
                            required property var modelData
                            required property int index

                            height: tape.height
                            text: modelData.text
                            // 28px between lines; none for an empty one, which takes no room.
                            leftPadding: text !== "" ? 14 : 0
                            rightPadding: leftPadding
                            color: index === Lyrics.index ? root.legend : Theme.text2
                        }
                    }
                }

                // The tape's ends fade into the bar's ground rather than cutting a word in half.
                Rectangle {
                    anchors.left: parent.left
                    width: 32
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Theme.ground
                        }
                        GradientStop {
                            position: 1
                            color: Qt.rgba(Theme.ground.r, Theme.ground.g, Theme.ground.b, 0)
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 32
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Qt.rgba(Theme.ground.r, Theme.ground.g, Theme.ground.b, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Theme.ground
                        }
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

    // Names the song while its lyrics stand in for it.
    Tooltip {
        anchorItem: root
        active: area.containsMouse && !popup.visible && root.tapeMode
        text: root.track
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
