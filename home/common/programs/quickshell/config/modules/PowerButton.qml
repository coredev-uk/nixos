import QtQuick
import qs.common
import qs.widgets

Icon {
    id: root

    text: Icons.power
    color: menu.visible ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        onClicked: menu.toggle()
    }

    PowerMenu {
        id: menu
        anchorItem: root
    }
}
