import QtQuick
import Quickshell
import qs.common

// Hover tooltip rendered as a popup above `target`, since bar windows are too short to host one.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool active: false

    anchor.item: target
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    visible: false
    color: "transparent"
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10 + gap

    readonly property int gap: 6

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
        anchors.bottomMargin: root.gap
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
