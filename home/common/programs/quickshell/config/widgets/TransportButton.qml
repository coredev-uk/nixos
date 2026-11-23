import QtQuick
import qs.common

// 28px player control on a cover-tinted surface: transparent at rest, glyph text2, light lifting
// under the pointer instead of a hover fill; "on" (playing, favourite) is gilt on a 10% tint, 16%
// on hover. Half opacity when the player can't do it.
Rectangle {
    id: root

    property alias icon: glyph.text
    property alias glyph: glyph
    property bool on: false

    signal clicked

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusRow
    color: on ? Theme.tint(Theme.gilt, area.containsMouse ? 0.16 : 0.1) : area.containsMouse ? Theme.tint(Theme.text, 0.08) : "transparent"
    opacity: enabled ? 1 : 0.5

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        font.pixelSize: 16
        renderType: Text.QtRendering
        color: root.on ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
