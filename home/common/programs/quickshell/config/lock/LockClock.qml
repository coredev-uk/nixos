import QtQuick
import Quickshell
import qs.common
import "sun.js" as Sun

// Bottom-left: the time, large, over the date and the next sunrise or sunset (the wallpaper
// follows the sun, so that's when the picture changes next). The date line gives way to the
// password (LockPrompt) while it's up.
Item {
    id: root

    required property AuthContext context
    property real s: 1
    property real margin: 80
    property real lineHeight: 56

    readonly property real clockSize: Math.round(300 * s)
    readonly property bool engaged: context.active && !context.unlocking

    // wlsunset's location, set by the quickshell-lock and quickshell-greeter wrappers.
    readonly property real latitude: parseFloat(Quickshell.env("QS_LOCK_LATITUDE") ?? "")
    readonly property real longitude: parseFloat(Quickshell.env("QS_LOCK_LONGITUDE") ?? "")
    readonly property var sun: isNaN(latitude) || isNaN(longitude) ? null : Sun.next(clock.date, latitude, longitude)

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        // Inter's digits carry side bearing; pull the ink onto the margin. The baseline sits a
        // fixed gap above the date line.
        x: root.margin - Math.round(0.035 * root.clockSize)
        y: parent.height - root.margin - root.lineHeight - Math.round(40 * root.s) - baselineOffset
        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.displayFontFamily
        font.pixelSize: root.clockSize
        font.weight: Font.Medium
        font.letterSpacing: -0.04 * root.clockSize
        // Colon centred on the digits.
        font.features: {
            "case": 1
        }
    }

    Row {
        x: root.margin
        y: parent.height - root.margin - (root.lineHeight + height) / 2
        spacing: Math.round(40 * root.s)
        opacity: root.engaged ? 0 : 1
        visible: opacity > 0

        transform: Translate {
            y: root.engaged ? Math.round(16 * root.s) : 0

            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }

        Text {
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(26 * root.s)
            font.weight: Font.Medium
        }

        Text {
            visible: root.sun !== null
            text: root.sun ? `${root.sun.label} ${Qt.formatTime(root.sun.time, "HH:mm")}` : ""
            color: Theme.text
            opacity: 0.72
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(26 * root.s)
            font.weight: Font.Medium
        }
    }
}
