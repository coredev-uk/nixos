import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Current track while playing; clicking opens its media card underneath. The track stays while
// the card is open, so pausing from it doesn't pull the bar item away.
Item {
    id: root

    readonly property var player: Media.player

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

        ScrollingText {
            Layout.maximumWidth: 600
            text: [root.player?.trackTitle, root.player?.trackArtist].filter(part => part).join(" - ")
            color: popup.visible ? Theme.gilt : Theme.text
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
