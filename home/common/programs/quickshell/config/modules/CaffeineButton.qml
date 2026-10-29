import QtQuick
import qs.common
import qs.services
import qs.widgets

Icon {
    id: root

    text: Caffeine.enabled ? Icons.coffee : Icons.coffeeOff
    color: Caffeine.enabled ? Theme.gilt : area.containsMouse ? Theme.text2 : Theme.muted

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Caffeine.enabled = !Caffeine.enabled
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse
        text: Caffeine.enabled ? "Staying awake (idle disabled)" : "Idle timers active"
    }
}
