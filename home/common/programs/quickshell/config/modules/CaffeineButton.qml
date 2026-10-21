import QtQuick
import qs.common
import qs.services
import qs.widgets

Icon {
    id: root

    text: Caffeine.enabled ? Icons.coffee : Icons.coffeeOff
    color: Caffeine.enabled ? Theme.peach : Theme.overlay0

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Caffeine.enabled = !Caffeine.enabled
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse
        text: Caffeine.enabled ? "Staying awake (idle disabled)" : "Idle timers active"
    }
}
