import QtQuick
import QtQuick.Layouts
import qs.common

// Selectable row in the panel sub-views (wifi networks, VPN countries, bluetooth devices, power
// actions). Transparent at rest, hover on hover; active or armed rows tint in their accent
// (gilt: connected, selected) and take it on the glyph and label.
Rectangle {
    id: root

    property string icon
    property bool emoji: false
    property string label
    property string sublabel
    property bool active: false
    property color accent: Theme.gilt

    signal clicked

    implicitHeight: row.implicitHeight + 16
    radius: Theme.radiusRow
    color: active ? Theme.tint(accent, area.containsMouse ? 0.16 : 0.1) : area.containsMouse ? Theme.hover : "transparent"
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

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 10

        Text {
            Layout.preferredWidth: 20
            text: root.icon
            // Muted only on a clear row; it sinks into the hover fill, so it lifts to text2 there.
            color: root.active ? root.accent : area.containsMouse ? Theme.text2 : Theme.muted
            font.family: root.emoji ? Theme.emojiFont : Theme.iconFont
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
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
            color: Theme.text2
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
