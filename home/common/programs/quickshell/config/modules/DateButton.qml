import QtQuick
import Quickshell
import qs.widgets

BarText {
    id: root

    required property SystemClock clock

    text: Qt.formatDateTime(clock.date, "ddd dd MMM")

    MouseArea {
        anchors.fill: parent
        onClicked: calendar.toggle()
    }

    CalendarPanel {
        id: calendar
        anchorItem: root
    }
}
