import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Right side of the password card: the time, then a list of notifications, network and (while
// something plays) the current track.
ColumnLayout {
    id: root

    property real s: 1

    spacing: Math.round(12 * s)

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Tile {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(140 * root.s)
        s: root.s

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Math.round(20 * root.s)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.s)

            Text {
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.displayFontFamily
                font.pixelSize: Math.round(56 * root.s)
                font.weight: Font.Bold
                font.features: {
                    "tnum": 1
                }
            }

            BarText {
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Theme.subtext0
                font.pixelSize: Math.round(14 * root.s)
            }
        }
    }

    Tile {
        Layout.fillWidth: true
        Layout.fillHeight: true
        s: root.s

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Math.round(20 * root.s)
            spacing: Math.round(16 * root.s)

            InfoRow {
                icon: NotificationCount.dnd ? Icons.bellOff : NotificationCount.count > 0 ? Icons.bellBadge : Icons.bell
                accent: Theme.mauve
                title: NotificationCount.count === 0 ? "No notifications" : NotificationCount.count === 1 ? "1 notification" : `${NotificationCount.count} notifications`
                subtitle: NotificationCount.dnd ? "Do Not Disturb is on" : NotificationCount.count > 0 ? "Waiting for you" : "All caught up"
            }

            InfoRow {
                icon: NetworkStatus.type === "ethernet" ? Icons.ethernet : NetworkStatus.type === "wifi" ? Icons.wifi : Icons.disconnected
                accent: NetworkStatus.type === "disconnected" ? Theme.red : Theme.teal
                // A wired connection's name is just the interface, so it gets a plain label.
                title: NetworkStatus.type === "ethernet" ? "Ethernet" : NetworkStatus.type === "wifi" ? (NetworkStatus.name || "Wi-Fi") : "Offline"
                subtitle: NetworkStatus.type === "disconnected" ? "No network" : NetworkStatus.type === "wifi" ? "Wi-Fi" : "Connected"
            }

            InfoRow {
                visible: Media.active
                icon: Icons.music
                artUrl: Media.player?.trackArtUrl ?? ""
                accent: Theme.pink
                title: Media.player?.trackTitle || "Unknown track"
                subtitle: Media.player?.trackArtist || (Media.player?.isPlaying ? "Playing" : "Paused")
                trailing: playPause
            }
        }
    }

    Component {
        id: playPause

        Rectangle {
            implicitWidth: Math.round(34 * root.s)
            implicitHeight: implicitWidth
            radius: width / 2
            color: playArea.containsMouse ? Theme.surface2 : Theme.surface1
            opacity: enabled ? 1 : 0.4
            enabled: Media.player?.canTogglePlaying ?? false

            Icon {
                anchors.centerIn: parent
                text: Media.player?.isPlaying ? Icons.pause : Icons.play
                color: Theme.text
                font.pixelSize: Math.round(16 * root.s)
            }

            MouseArea {
                id: playArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.player.togglePlaying()
            }
        }
    }

    // Icon badge (or artwork), a title and subtitle that elide, and an optional control on the right.
    component InfoRow: RowLayout {
        id: info

        property string icon
        property color accent
        property string title
        property string subtitle
        // Shown in place of the icon once it loads.
        property string artUrl: ""
        property Component trailing: null

        Layout.fillWidth: true
        spacing: Math.round(14 * root.s)

        ClippingRectangle {
            Layout.preferredWidth: Math.round(40 * root.s)
            Layout.preferredHeight: Math.round(40 * root.s)
            radius: Math.round(12 * root.s)
            color: Qt.rgba(info.accent.r, info.accent.g, info.accent.b, 0.16)

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: info.icon
                color: info.accent
                font.pixelSize: Math.round(20 * root.s)
            }

            Image {
                id: art

                anchors.fill: parent
                source: info.artUrl
                sourceSize.width: 128
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * root.s)

            BarText {
                Layout.fillWidth: true
                text: info.title
                elide: Text.ElideRight
                font.pixelSize: Math.round(15 * root.s)
                font.weight: Font.DemiBold
            }

            BarText {
                Layout.fillWidth: true
                text: info.subtitle
                elide: Text.ElideRight
                color: Theme.subtext0
                font.pixelSize: Math.round(13 * root.s)
            }
        }

        Loader {
            active: info.trailing !== null
            sourceComponent: info.trailing
        }
    }
}
