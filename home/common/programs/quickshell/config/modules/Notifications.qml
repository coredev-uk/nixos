import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
    id: root

    readonly property int count: NotificationService.count
    readonly property bool dnd: NotificationService.dnd
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
        // Left: open the notification centre. Right: toggle Do Not Disturb.
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                NotificationService.toggleDnd();
            else
                center.toggle();
        }
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !center.visible
        text: `${root.count} notification${root.count === 1 ? "" : "s"}${root.dnd ? " · Do not disturb" : ""}`
    }

    NotificationCenter {
        id: center
        anchorItem: root
    }

    // The IPC toggle opens the centre of the focused monitor's bar.
    Connections {
        target: NotificationService

        function onCenterToggled(screen) {
            if (screen === "" || screen === root.QsWindow.window?.screen?.name)
                center.toggleFromIpc();
        }
    }
}
