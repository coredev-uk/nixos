import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Now-playing card: album art fills the background behind a scrim, with track text and controls on top.
ClippingRectangle {
    id: root

    readonly property MprisPlayer player: Media.player

    implicitHeight: Math.max(90, overlay.implicitHeight + 20)
    radius: 10
    color: Theme.surface0

    Image {
        id: art
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        sourceSize.width: 640
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Keeps the text legible over bright artwork.
    Rectangle {
        anchors.fill: parent
        visible: art.status === Image.Ready
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    component MediaButton: Rectangle {
        id: button

        property alias icon: label.text

        signal clicked

        implicitWidth: label.implicitWidth + 24
        implicitHeight: label.implicitHeight + 12
        radius: 8
        color: area.containsMouse ? Qt.rgba(Theme.pink.r, Theme.pink.g, Theme.pink.b, 0.15) : "transparent"
        opacity: enabled ? 1 : 0.4

        Icon {
            id: label
            anchors.centerIn: parent
            color: Theme.pink
            font.pixelSize: 18
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    ColumnLayout {
        id: overlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 10
        spacing: 4

        BarText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Unknown Track"
            color: Theme.pink
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
        }

        BarText {
            Layout.fillWidth: true
            text: root.player?.trackArtist || "Unknown Artist"
            color: Theme.text
            opacity: 0.9
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Row {
            spacing: 20

            MediaButton {
                icon: Icons.previous
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            MediaButton {
                icon: root.player?.isPlaying ? Icons.pause : Icons.play
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }

            MediaButton {
                icon: Icons.next
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }
    }
}
