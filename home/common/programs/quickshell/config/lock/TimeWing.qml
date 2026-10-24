import QtQuick
import Quickshell
import qs.common
import qs.widgets

// Left side of the password card: the time and date.
Tile {
    id: root

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: Math.round(2 * root.s)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
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
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            color: Theme.subtext0
            font.pixelSize: Math.round(14 * root.s)
        }
    }
}
