import QtQuick
import qs.common

Item {
    id: root

    property real value: 0 // 0-100
    property color color: Theme.blue
    readonly property real fraction: Math.max(0, Math.min(1, value / 100))

    signal moved(real value)

    implicitWidth: 70
    implicitHeight: 16

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface0

        Rectangle {
            width: parent.width * root.fraction
            height: parent.height
            radius: parent.radius
            color: root.color
        }
    }

    MouseArea {
        anchors.fill: parent

        function update(x: real) {
            root.moved(Math.round(Math.max(0, Math.min(1, x / width)) * 100));
        }

        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(100, Math.round(root.value) + (wheel.angleDelta.y > 0 ? 5 : -5))))
    }
}
