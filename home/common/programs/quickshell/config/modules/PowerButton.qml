import QtQuick
import qs.common
import qs.widgets

Icon {
    id: root

    text: Icons.power
    color: menu.visible ? Theme.red : Theme.subtext0

    MouseArea {
        anchors.fill: parent
        onClicked: menu.toggle()
    }

    PowerMenu {
        id: menu
        anchorItem: root
    }
}
