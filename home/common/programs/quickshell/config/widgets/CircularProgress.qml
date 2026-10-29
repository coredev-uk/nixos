import QtQuick
import QtQuick.Shapes
import qs.common

Item {
    id: root

    property real value: 0 // 0-100
    property color color: Theme.fill
    property real thickness: 3
    property alias icon: label.text

    implicitWidth: 20
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.inset
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: -90
                sweepAngle: 3.6 * Math.max(0, Math.min(100, root.value))
            }
        }
    }

    Icon {
        id: label
        anchors.centerIn: parent
        color: root.color
        font.pixelSize: 11
    }
}
