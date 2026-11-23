import QtQuick
import qs.common
import qs.services
import qs.widgets

// Shown only while a peripheral is at or below 15% and not charging: alert glyph in caution (alert
// at 10% or less, as on its chip). Click opens the Connections panel.
Icon {
    id: root

    readonly property var low: Batteries.low
    readonly property bool critical: low.some(device => device.level <= 10)

    signal activated

    visible: low.length > 0
    text: Icons.batteryAlert
    color: critical ? Theme.alert : Theme.caution

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse
        text: `Low battery: ${root.low.map(device => `${device.short} ${device.level}%`).join(" · ")}`
    }
}
