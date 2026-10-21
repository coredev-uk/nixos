import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property string title

    signal clicked

    Layout.fillWidth: true
    Layout.bottomMargin: 4
    implicitHeight: row.implicitHeight + 16
    radius: 8
    color: area.containsMouse ? Theme.surface0 : "transparent"

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Icon {
            text: Icons.chevronLeft
            color: Theme.overlay0
            font.pixelSize: 14
        }

        BarText {
            Layout.fillWidth: true
            text: root.title
            color: Theme.subtext1
            font.pixelSize: 12
            font.bold: true
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
