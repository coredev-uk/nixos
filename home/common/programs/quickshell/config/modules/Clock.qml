import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.widgets
import "../common/sun.js" as Sun

// "Wed 28 Oct ─●─ 13:23": the date, the day arc, the time. The arc is the day as a 24-hour
// track: the daylight span between today's sunrise and sunset is lit, with a tick at each, and
// a gilt dot marks now, so it reads at a glance how much light is left (the wallpaper follows
// the same sun). Any of it opens the calendar.
Item {
    id: root

    // wlsunset's location, from the bar's service environment (default.nix).
    readonly property real latitude: parseFloat(Quickshell.env("QS_LATITUDE") ?? "")
    readonly property real longitude: parseFloat(Quickshell.env("QS_LONGITUDE") ?? "")
    readonly property var sun: isNaN(latitude) || isNaN(longitude) ? null : Sun.events(clock.date, latitude, longitude)
    readonly property bool open: calendar.visible

    function dayFraction(date: date): real {
        return (date.getHours() * 60 + date.getMinutes()) / 1440;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 10

    BarText {
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: root.open ? Theme.gilt : Theme.text2
    }

    Item {
        id: arc

        readonly property real rise: root.sun ? root.dayFraction(root.sun.rise) : 0
        readonly property real set: root.sun ? root.dayFraction(root.sun.set) : 0
        readonly property real now: root.dayFraction(clock.date)

        visible: root.sun !== null
        implicitWidth: 120
        implicitHeight: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 2
            color: Theme.rule
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(arc.rise * arc.width)
            width: Math.round((arc.set - arc.rise) * arc.width)
            height: 2
            color: Theme.tint(Theme.text, 0.42)
        }

        Repeater {
            model: [arc.rise, arc.set]

            Rectangle {
                required property real modelData

                x: Math.round(modelData * arc.width)
                width: 1
                height: 6
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.tint(Theme.text, 0.7)
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(arc.now * arc.width) - width / 2
            width: 7
            height: 7
            radius: width / 2
            color: Theme.gilt
            border.color: Theme.ground
            border.width: 1
        }

        HoverHandler {
            id: arcHover
        }

        Tooltip {
            anchorItem: arc
            active: arcHover.hovered && !calendar.visible
            text: root.sun ? `Sunrise ${Qt.formatTime(root.sun.rise, "HH:mm")} · Sunset ${Qt.formatTime(root.sun.set, "HH:mm")}` : ""
        }
    }

    BarText {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: root.open ? Theme.gilt : Theme.text
        font.bold: true
    }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: calendar.toggle()
    }

    CalendarPanel {
        id: calendar
        anchorItem: root
    }
}
