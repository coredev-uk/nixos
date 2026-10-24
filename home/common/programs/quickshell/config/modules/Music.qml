import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Current track while playing; controls live in the network panel's media card.
RowLayout {
    id: root

    readonly property var player: Media.player

    visible: player?.isPlaying ?? false
    spacing: 6

    ClippingRectangle {
        visible: (root.player?.trackArtUrl ?? "") !== ""
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: Theme.surface0

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
    }
}
