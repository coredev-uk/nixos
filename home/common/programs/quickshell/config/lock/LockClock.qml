import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Idle face: two-tone clock and date over the wallpaper, a now-playing line and a hint at the bottom.
// Folds away while the password card is up.
Item {
    id: root

    required property LockContext context
    property real s: 1

    readonly property bool concealed: context.active || context.unlocking

    opacity: concealed ? 0 : 1
    scale: concealed ? 0.92 : 1
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    component ClockText: Text {
        font.family: Theme.displayFontFamily
        font.pixelSize: Math.round(168 * root.s)
        font.weight: Font.Bold
        font.letterSpacing: -0.02 * Math.round(168 * root.s)
        // Tabular digits keep the clock from shifting as it ticks.
        font.features: {
            "tnum": 1
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.36 - height / 2)
        spacing: Math.round(4 * root.s)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.crust
            shadowOpacity: 0.45
            shadowBlur: 0.6
            shadowVerticalOffset: Math.round(3 * root.s)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(6 * root.s)

            ClockText {
                text: Qt.formatTime(clock.date, "HH")
                color: Theme.blue
            }

            ClockText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Math.round(-8 * root.s)
                text: ":"
                color: Theme.subtext0
                font.pixelSize: Math.round(112 * root.s)
            }

            ClockText {
                text: Qt.formatTime(clock.date, "mm")
                color: Theme.text
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, d MMMM").toUpperCase()
            color: Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(17 * root.s)
            font.weight: Font.DemiBold
            font.letterSpacing: 2.5 * root.s
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(48 * root.s)
        spacing: Math.round(18 * root.s)

        // Now playing, as a quiet pill.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Media.active
            width: nowPlaying.implicitWidth + Math.round(36 * root.s)
            height: Math.round(40 * root.s)
            radius: height / 2
            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.6)

            Row {
                id: nowPlaying

                anchors.centerIn: parent
                spacing: Math.round(10 * root.s)

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.music
                    color: Theme.blue
                    font.pixelSize: Math.round(16 * root.s)
                }

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.round(520 * root.s))
                    elide: Text.ElideRight
                    text: [Media.player?.trackTitle, Media.player?.trackArtist].filter(part => part).join("  ·  ")
                    font.pixelSize: Math.round(14 * root.s)
                    font.weight: Font.Medium
                }
            }
        }

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Type or click to unlock"
            color: Theme.subtext0
            font.pixelSize: Math.round(14 * root.s)

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.35
                    duration: 1400
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0.9
                    duration: 1400
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
