import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

// Panel row: icon (glyph or app icon), optional label, a full-width slider, the value in percent,
// and optionally a chevron that expands extra content below the row.
Item {
    id: root

    property string icon
    // App icon path; replaces the glyph when set.
    property string iconSource: ""
    property string label: ""
    property color color: Theme.blue
    property real value: 0 // 0-100
    property bool expandable: false
    property bool expanded: false

    signal moved(real value)
    signal iconClicked
    signal expandToggled

    implicitHeight: row.implicitHeight + 16

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Item {
            Layout.preferredWidth: 28
            implicitHeight: glyph.implicitHeight

            Icon {
                id: glyph
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: root.icon
                color: root.color
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.iconSource !== ""
                source: root.iconSource
                implicitSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.iconClicked()
            }
        }

        BarText {
            visible: root.label !== ""
            Layout.preferredWidth: 80
            text: root.label
            color: Theme.subtext1
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        BarSlider {
            Layout.fillWidth: true
            value: root.value
            color: root.color
            onMoved: value => root.moved(value)
        }

        BarText {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(root.value)}%`
            color: Theme.subtext0
            font.pixelSize: 11
        }

        Rectangle {
            visible: root.expandable
            implicitWidth: 22
            implicitHeight: 22
            radius: 6
            color: expandArea.containsMouse ? Theme.surface0 : "transparent"

            Icon {
                anchors.centerIn: parent
                text: root.expanded ? Icons.chevronUp : Icons.chevronDown
                color: Theme.overlay0
                font.pixelSize: 14
            }

            MouseArea {
                id: expandArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.expandToggled()
            }
        }
    }
}
