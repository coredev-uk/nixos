import QtQuick
import qs.common
import qs.services
import qs.widgets

// The playing song's timed lyrics in now playing's card (NowPlayingCard.qml), shown only on Sona,
// flush left, read downward like a score: the sung line in 15px Medium text; the line coming next
// in text2 and the one just gone in muted, both drawn at 85% so their places don't move as a line
// takes or gives up the weight; a line further off is faded out rather than cut at the edge. A new
// line moves the list up (Move) while the size and colour change (State). Between lines the next
// one waits in the sung line's place, in text2 until it is sung. A sung line too long for the
// column wraps onto a second. Without timed lyrics, one line in their place says why.
Item {
    id: root

    readonly property int textSize: 15
    // Lines shown above and below the one in the sung line's place.
    readonly property int context: 1
    readonly property bool ready: Lyrics.status === "ready" && Lyrics.lines.length > 0 && Lyrics.title === (Media.player?.trackTitle ?? "")
    readonly property int pad: 6
    readonly property real lineHeight: Math.ceil(metrics.height) + pad

    FontMetrics {
        id: metrics
        font.family: Theme.fontFamily
        font.pixelSize: root.textSize
    }

    ListView {
        id: list

        anchors.fill: parent
        visible: root.ready
        clip: true
        interactive: false
        model: Lyrics.lines
        // Set, not bound: ListView resets currentIndex to 0 when its model changes, which would
        // break a binding for good.
        function follow() {
            currentIndex = Math.max(0, Math.min(count - 1, Lyrics.focus));
        }

        Connections {
            target: Lyrics
            function onFocusChanged() {
                list.follow();
            }
        }

        // The sung line, however many lines it wraps to, keeps one place: one line down, so the
        // line just gone shows whole above it and the next one below. Its height is read after
        // the list has laid out (Qt.callLater): bound to currentItem directly, the range would
        // move the current item and the current item the range.
        property real sungHeight: root.lineHeight

        function syncSung() {
            sungHeight = currentItem?.height ?? root.lineHeight;
        }

        onCurrentItemChanged: Qt.callLater(syncSung)

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: root.lineHeight
        preferredHighlightEnd: preferredHighlightBegin + sungHeight
        // Opening the card or a new song's lines are placed at once; only a new line glides.
        highlightMoveDuration: placed ? Theme.durationMove : 0

        property bool placed: false

        function place() {
            placed = false;
            settle.restart();
        }

        onVisibleChanged: {
            place();
            follow();
        }
        onCountChanged: {
            place();
            Qt.callLater(follow);
        }

        Timer {
            id: settle
            interval: 150
            onTriggered: list.placed = true
        }

        delegate: Item {
            id: line

            required property var modelData
            required property int index
            readonly property bool sung: index === Lyrics.index
            readonly property bool coming: index >= Lyrics.focus && !sung
            readonly property bool near: Math.abs(index - list.currentIndex) <= root.context

            width: ListView.view.width
            height: modelData.text !== "" ? label.implicitHeight + root.pad : 0

            onHeightChanged: {
                if (index === list.currentIndex)
                    Qt.callLater(list.syncSung);
            }

            BarText {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                text: line.modelData.text
                wrapMode: Text.WordWrap
                maximumLineCount: line.sung ? 2 : 1
                elide: Text.ElideRight
                color: line.sung ? Theme.text : line.coming ? Theme.text2 : Theme.muted
                font.pixelSize: root.textSize
                font.weight: line.sung ? Font.Medium : Font.Normal
                // Outlines, so the scaled lines stay sharp.
                renderType: Text.QtRendering
                transformOrigin: Item.Left
                scale: line.sung ? 1 : 0.85
                opacity: line.near ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }
        }
    }

    BarText {
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height / 3 - height / 2)
        width: parent.width
        visible: !root.ready
        elide: Text.ElideRight
        color: Theme.text2
        font.pixelSize: 13
        text: {
            switch (Lyrics.status) {
            case "none":
                return "No lyrics for this song";
            case "plain":
                return "This song's lyrics have no timing";
            default:
                return "Finding lyrics…";
            }
        }
    }
}
