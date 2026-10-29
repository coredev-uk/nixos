import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

Item {
    id: root

    readonly property int count: NotificationService.count
    readonly property int unread: NotificationService.unread
    readonly property bool dnd: NotificationService.dnd
    // Enamel at rest, text under the pointer; the whole item is gilt while its centre is open.
    readonly property color rest: center.visible ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2
    // The bell is gilt while something is unread; muted under Do Not Disturb. The count of what's
    // kept stays enamel: having notifications isn't "on".
    readonly property color bellTint: center.visible || (unread > 0 && !dnd) ? Theme.gilt : dnd ? Theme.muted : rest

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 4

        Icon {
            text: root.dnd ? Icons.bellOff : root.unread > 0 ? Icons.bellBadge : Icons.bell
            color: root.bellTint
        }

        BarText {
            visible: root.count > 0
            text: root.count
            color: root.rest
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
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
        text: {
            const kept = `${root.count} notification${root.count === 1 ? "" : "s"}`;
            const fresh = root.unread > 0 ? `, ${root.unread} new` : "";
            const quiet = root.dnd ? " · Do not disturb" : Privacy.onAir ? " · Popups held while sharing" : "";
            return kept + fresh + quiet;
        }
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
