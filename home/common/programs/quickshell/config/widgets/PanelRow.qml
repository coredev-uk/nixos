import QtQuick
import QtQuick.Layouts
import qs.common

// Main panel row: a 32px inset glyph tile toggles the service (gilt glyph when on), the rest
// opens its sub-view. Rows without a toggle (canToggle: false) open from the tile too.
Rectangle {
    id: root

    property string icon
    property bool on: false
    // A state colour for the glyph when it reports something other than on/off (an error).
    property color iconColor: on ? Theme.gilt : Theme.muted
    property string label
    property string sublabel
    property bool canOpen: true
    property bool canToggle: true

    signal toggled
    signal opened

    Layout.fillWidth: true
    implicitHeight: 48
    radius: Theme.radiusRow
    color: hover.hovered ? Theme.hover : "transparent"

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: Theme.radiusRow
            color: toggleArea.containsMouse && root.canToggle ? Theme.rule : Theme.inset

            Icon {
                anchors.centerIn: parent
                text: root.icon
                color: root.iconColor

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }

            MouseArea {
                id: toggleArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.canToggle ? root.toggled() : root.opened()
            }
        }

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Rows with nothing to open toggle on a click anywhere.
            onClicked: root.canOpen ? root.opened() : root.toggled()

            RowLayout {
                anchors.fill: parent
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    BarText {
                        text: root.label
                        font.pixelSize: 13
                        font.bold: true
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: root.sublabel
                        color: Theme.text2
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Icon {
                    visible: root.canOpen
                    text: Icons.chevronRight
                    color: Theme.muted
                    font.pixelSize: 14
                }
            }
        }
    }
}
