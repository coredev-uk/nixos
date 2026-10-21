import QtQuick
import QtQuick.Layouts
import qs.common

// Panel row with an icon, a full-width slider and the value in percent.
Item {
    id: root

    property string icon
    property color color: Theme.blue
    property real value: 0 // 0-100

    signal moved(real value)
    signal iconClicked

    implicitHeight: row.implicitHeight + 16

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Icon {
            Layout.preferredWidth: 28
            text: root.icon
            color: root.color

            MouseArea {
                anchors.fill: parent
                onClicked: root.iconClicked()
            }
        }

        BarSlider {
            Layout.fillWidth: true
            value: root.value
            color: root.color
            onMoved: value => root.moved(value)
        }

        BarText {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(root.value)}%`
            color: Theme.subtext0
            font.pixelSize: 11
        }
    }
}
