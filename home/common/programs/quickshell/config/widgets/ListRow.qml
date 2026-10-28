import QtQuick
import QtQuick.Layouts
import qs.common

// Selectable row in the network panel sub-views (wifi networks, VPN countries, bluetooth devices).
Rectangle {
    id: root

    property string icon
    property bool emoji: false
    property string label
    property string sublabel
    property bool active: false
    property color accent: Theme.green

    signal clicked

    implicitHeight: row.implicitHeight + 16
    radius: 6
    color: active ? Qt.rgba(accent.r, accent.g, accent.b, 0.1) : area.containsMouse ? Theme.surface0 : "transparent"
    opacity: enabled ? 1 : 0.5

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            Layout.preferredWidth: root.emoji ? 20 : 16
            text: root.icon
            color: root.active ? root.accent : Theme.overlay0
            font.family: root.emoji ? Theme.emojiFont : Theme.iconFont
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        BarText {
            Layout.fillWidth: true
            text: root.label
            color: root.active ? root.accent : Theme.text
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        BarText {
            text: root.sublabel
            color: Theme.subtext0
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
