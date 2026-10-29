import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common
import qs.widgets

Row {
    visible: SystemTray.items.values.length > 0
    spacing: 10

    Repeater {
        model: SystemTray.items

        Item {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: 15
            implicitHeight: 15

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
                implicitSize: 15
            }

            // The icon stays 15px; the target takes half the gap either side and the bar's full
            // height, so it's 25×24 without moving anything.
            MouseArea {
                id: area
                anchors.fill: parent
                anchors.leftMargin: -5
                anchors.rightMargin: -5
                anchors.topMargin: -Math.ceil((Theme.barHeight - item.height) / 2)
                anchors.bottomMargin: -Math.ceil((Theme.barHeight - item.height) / 2)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !item.modelData.onlyMenu)
                        item.modelData.activate();
                    else if (mouse.button === Qt.MiddleButton)
                        item.modelData.secondaryActivate();
                    else if (item.modelData.hasMenu)
                        menu.toggle();
                }
            }

            Tooltip {
                anchorItem: item
                active: area.containsMouse && !menu.visible
                text: item.modelData.tooltipTitle || item.modelData.title || item.modelData.id
            }

            TrayMenu {
                id: menu
                anchorItem: item
                menu: item.modelData.menu
            }
        }
    }
}
