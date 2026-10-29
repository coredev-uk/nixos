import QtQuick
import QtQuick.Layouts
import qs.common

// Heads every sub-view: chevron back, then the view's title.
Rectangle {
    id: root

    property string title

    signal clicked

    Layout.fillWidth: true
    Layout.bottomMargin: 4
    implicitHeight: row.implicitHeight + 16
    radius: Theme.radiusRow
    color: area.containsMouse ? Theme.hover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 8

        Icon {
            Layout.preferredWidth: 16
            text: Icons.chevronLeft
            // Lifts to text2 on the hover fill, where muted sinks in.
            color: area.containsMouse ? Theme.text2 : Theme.muted
            font.pixelSize: 14
        }

        BarText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: 13
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
