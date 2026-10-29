import QtQuick
import Quickshell
import qs.common
import "../common/sun.js" as Sun

// Bottom-left: the time, large, over the date, the day arc and the next sunrise or sunset (the
// wallpaper follows the sun, so that's when the picture changes next). The arc is the bar
// clock's, at this size: the day as a 24-hour track with the daylight between today's sunrise
// and sunset lit, a tick and the time at each, and a gilt dot at now. The date line gives way to
// the password (LockPrompt) while it's up.
Item {
    id: root

    required property AuthContext context
    property real s: 1
    property real margin: 80
    property real lineHeight: 56

    readonly property real clockSize: Math.round(300 * s)
    readonly property bool engaged: context.active && !context.unlocking

    // wlsunset's location, set by the quickshell-lock and quickshell-greeter wrappers.
    readonly property real latitude: parseFloat(Quickshell.env("QS_LATITUDE") ?? "")
    readonly property real longitude: parseFloat(Quickshell.env("QS_LONGITUDE") ?? "")
    readonly property bool located: !isNaN(latitude) && !isNaN(longitude)
    readonly property var sun: located ? Sun.next(clock.date, latitude, longitude) : null
    // Today's sunrise and sunset, for the arc.
    readonly property var day: located ? Sun.events(clock.date, latitude, longitude) : null

    function dayFraction(date: date): real {
        return (date.getHours() * 60 + date.getMinutes()) / 1440;
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // The first digit's ink, measured rather than assumed, so the time lines up with the date
    // line on the margin whatever the hour's leading digit and its side bearing.
    TextMetrics {
        id: ink

        font: time.font
        text: time.text
    }

    Text {
        id: time

        // The baseline sits a fixed gap above the date line.
        x: root.margin - Math.round(ink.tightBoundingRect.x)
        y: parent.height - root.margin - root.lineHeight - Math.round(40 * root.s) - baselineOffset
        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.displayFontFamily
        font.pixelSize: root.clockSize
        font.weight: Font.Light
        font.letterSpacing: -0.03 * root.clockSize
        // Tabular figures, so the colon holds still as the minutes turn.
        font.features: Theme.fontFeatures
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
                    easing.type: Theme.easing
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Theme.easing
            }
        }

        Text {
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(26 * root.s)
            font.weight: Font.Medium
        }

        Item {
            id: arc

            readonly property real rise: root.day ? root.dayFraction(root.day.rise) : 0
            readonly property real set: root.day ? root.dayFraction(root.day.set) : 0
            readonly property real now: root.dayFraction(clock.date)
            readonly property real track: Math.round(3 * root.s)

            anchors.verticalCenter: parent.verticalCenter
            visible: root.day !== null
            width: Math.round(360 * root.s)
            height: Math.round(12 * root.s)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: arc.track
                color: Theme.rule
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(arc.rise * arc.width)
                width: Math.round((arc.set - arc.rise) * arc.width)
                height: arc.track
                color: Theme.tint(Theme.text, 0.42)
            }

            // Sunrise and sunset: a tick across the track, its time under it (outside the
            // arc's height, so the line stays centred on the date).
            Repeater {
                model: root.day ? [root.day.rise, root.day.set] : []

                Item {
                    id: tick

                    required property var modelData
                    readonly property real at: Math.round(root.dayFraction(modelData) * arc.width)

                    anchors.fill: parent

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: tick.at - Math.floor(width / 2)
                        width: Math.max(1, Math.round(1.5 * root.s))
                        height: Math.round(10 * root.s)
                        color: Theme.tint(Theme.text, 0.7)
                    }

                    Text {
                        x: tick.at - Math.round(implicitWidth / 2)
                        y: parent.height / 2 + Math.round(12 * root.s)
                        text: Qt.formatTime(tick.modelData, "HH:mm")
                        color: Theme.text2
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(14 * root.s)
                        font.features: Theme.fontFeatures
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(arc.now * arc.width) - width / 2
                width: Math.round(11 * root.s)
                height: width
                radius: width / 2
                color: Theme.gilt
                border.color: Theme.ground
                border.width: Math.max(1, Math.round(2 * root.s))
            }
        }

        Text {
            visible: root.sun !== null
            text: root.sun ? `${root.sun.label} ${Qt.formatTime(root.sun.time, "HH:mm")}` : ""
            color: Theme.text2
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(26 * root.s)
            font.weight: Font.Medium
            font.features: Theme.fontFeatures
        }
    }
}
