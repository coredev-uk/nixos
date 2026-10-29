import QtQuick
import qs.common

// 4px inset track with an enamel fill; click, drag, or wheel in 5% steps.
Item {
    id: root

    property real value: 0 // 0-100
    property color color: Theme.fill
    readonly property real fraction: Math.max(0, Math.min(1, value / 100))

    signal moved(real value)

    implicitWidth: 70
    implicitHeight: 16

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.inset

        Rectangle {
            width: parent.width * root.fraction
            height: parent.height
            radius: parent.radius
            color: root.color

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
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
