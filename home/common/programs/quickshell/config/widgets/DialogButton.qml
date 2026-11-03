import QtQuick
import qs.common

// Button at the foot of a dialog: outlined, or filled gilt for the dialog's one primary action.
Rectangle {
    id: root

    property string label
    property bool primary: false

    signal clicked

    implicitWidth: Math.max(88, text.implicitWidth + 28)
    implicitHeight: 32
    radius: Theme.radiusInset
    color: primary ? (area.containsMouse ? Theme.giltHover : Theme.gilt) : area.containsMouse ? Theme.hover : "transparent"
    border.width: primary ? 0 : 1
    border.color: Theme.rule
    opacity: enabled ? 1 : 0.5

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    BarText {
        id: text

        anchors.centerIn: parent
        text: root.label
        color: root.primary ? Theme.ground : Theme.text
        font.pixelSize: 12
        font.bold: root.primary
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
