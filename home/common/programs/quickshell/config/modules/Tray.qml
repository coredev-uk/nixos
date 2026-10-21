import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

Row {
    spacing: 10

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: 15
            implicitHeight: 15
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu)
                    modelData.activate();
                else if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (modelData.hasMenu)
                    menu.open();
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
                implicitSize: 15
            }

            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: Theme.popupEdges
                anchor.gravity: Theme.popupEdges
            }
        }
    }
}
