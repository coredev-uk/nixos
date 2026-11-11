import QtQuick
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// The playing song's lyrics under the media card in now playing's popup (Music.qml), while Sona
// has timed lyrics for it (services/Lyrics.qml). An inset well with the line being sung centred
// in text, the lines either side in text2 and the ones further off in muted, wrapping to the
// well's width; the list's ends fade into the well. Each new line glides the list up (Move) as
// the colours step (State); between lines the next one waits at the centre in text2. Opening
// the popup places the list without gliding.
ClippingRectangle {
    id: root

    // Whether the popup is showing; the list only glides while it is.
    property bool active: false

    readonly property bool shown: Lyrics.title === (Media.player?.trackTitle ?? "") && Lyrics.lines.some(line => line.text !== "")

    implicitHeight: 176
    radius: Theme.radiusInset
    color: Theme.inset

    // A new song's lines, or a popup that has just opened, are placed rather than glided.
    property bool glide: false

    function settle() {
        glide = false;
        glideOn.restart();
    }
    onActiveChanged: settle()

    Connections {
        target: Lyrics
        function onLinesChanged() {
            root.settle();
        }
    }

    Timer {
        id: glideOn
        interval: 100
        onTriggered: root.glide = root.active
    }

    Column {
        id: list

        readonly property Item focusItem: lineItems.count > 0 && Lyrics.focus >= 0 ? lineItems.itemAt(Lyrics.focus) : null

        x: 14
        width: root.width - 28
        spacing: 10
        y: focusItem ? Math.round(root.height / 2 - focusItem.y - focusItem.height / 2) : 0

        Behavior on y {
            enabled: root.glide
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

                readonly property int distance: Math.abs(index - Lyrics.focus)

                width: list.width
                // An empty line (an instrumental break in some lyrics) takes no room.
                height: text !== "" ? implicitHeight : 0
                visible: text !== ""
                text: modelData.text
                wrapMode: Text.WordWrap
                lineHeight: 1.15
                font.pixelSize: 15
                color: index === Lyrics.index ? Theme.text : distance <= 1 ? Theme.text2 : Theme.muted
            }
        }
    }

    // The list's ends fade into the well rather than cutting a line in half.
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 36
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.inset
            }
            GradientStop {
                position: 1
                color: Theme.tint(Theme.inset, 0)
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 36
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.tint(Theme.inset, 0)
            }
            GradientStop {
                position: 1
                color: Theme.inset
            }
        }
    }
}
