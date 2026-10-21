import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
    id: root

    readonly property int count: NotificationCount.count
    readonly property bool dnd: NotificationCount.dnd
    readonly property color tint: dnd ? Theme.overlay0 : count > 0 ? Theme.peach : Theme.subtext0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 4

        Icon {
            text: root.dnd ? Icons.bellOff : root.count > 0 ? Icons.bellBadge : Icons.bell
            color: root.tint
        }

        BarText {
            visible: root.count > 0
            text: root.count
            color: root.tint
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Left: open the notification center. Right: toggle Do Not Disturb.
        onClicked: mouse => Quickshell.execDetached(mouse.button === Qt.RightButton ? ["swaync-client", "-d", "-sw"] : ["swaync-client", "-t", "-sw"])
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse
        text: `${root.count} notification${root.count === 1 ? "" : "s"}${root.dnd ? " · Do Not Disturb" : ""}`
    }
}
