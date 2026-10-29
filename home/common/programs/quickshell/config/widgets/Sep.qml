import QtQuick
import qs.common

// 1px rule between groups of bar items, in a 21px slot (10px either side).
Item {
    implicitWidth: 1
    implicitHeight: 14

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 14
        color: Theme.rule
    }
}
