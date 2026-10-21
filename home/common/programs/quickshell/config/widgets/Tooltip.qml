import QtQuick
import qs.common

// Hover tooltip rendered as a popup, since bar windows are too short to host one.
BarPopup {
    id: root

    property string text: ""
    property bool active: false

    gap: 6
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10 + gap

    onActiveChanged: {
        if (active) {
            delay.restart();
        } else {
            delay.stop();
            visible = false;
        }
    }

    Timer {
        id: delay
        interval: 400
        onTriggered: root.visible = root.text !== ""
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        radius: 6
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        BarText {
            id: label
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: 12
        }
    }
}
