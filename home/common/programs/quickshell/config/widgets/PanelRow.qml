import QtQuick
import QtQuick.Layouts
import qs.common

// Main network panel row: left icon toggles the service, the rest opens its sub-view.
// Rows without a toggle (canToggle: false) open from the icon too.
Rectangle {
    id: root

    property string icon
    property color iconColor: Theme.green
    property string label
    property string sublabel
    property bool canOpen: true
    property bool canToggle: true

    signal toggled
    signal opened

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + 20
    radius: 8
    color: hover.hovered ? Theme.surface0 : "transparent"

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            implicitWidth: toggleIcon.implicitWidth + 16
            implicitHeight: toggleIcon.implicitHeight + 8
            radius: 6
            color: toggleArea.containsMouse && root.canToggle ? Theme.surface1 : "transparent"

            Icon {
                id: toggleIcon
                anchors.centerIn: parent
                width: 20
                text: root.icon
                color: root.iconColor
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
            implicitHeight: content.implicitHeight
            // Rows with nothing to open toggle on a click anywhere.
            onClicked: root.canOpen ? root.opened() : root.toggled()

            RowLayout {
                id: content
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
                        color: Theme.subtext0
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Icon {
                    visible: root.canOpen
                    text: Icons.chevronRight
                    color: Theme.overlay0
                    font.pixelSize: 14
                }
            }
        }
    }
}
