import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

// Panel row: icon (glyph or app icon), optional label, a full-width slider, its value (percent
// unless valueText says otherwise), and optionally a chevron that expands extra content below the row.
// The chevron's slot is kept on every row so tracks and values line up down the panel.
Item {
    id: root

    property string icon
    // App icon path; replaces the glyph when set.
    property string iconSource: ""
    property string label: ""
    // The fill; muted when the thing it sets is off (a muted output).
    property color color: Theme.fill
    property color iconColor: Theme.text2
    property real value: 0 // 0-100
    property string valueText: `${Math.round(value)}%`
    property bool expandable: false
    property bool expanded: false

    signal moved(real value)
    signal iconClicked
    signal expandToggled

    implicitHeight: row.implicitHeight + 16

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Item {
            Layout.preferredWidth: 28
            implicitHeight: glyph.implicitHeight

            Icon {
                id: glyph
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: root.icon
                color: root.iconColor
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
            color: Theme.text2
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        BarSlider {
            Layout.fillWidth: true
            value: root.value
            color: root.color
            onMoved: value => root.moved(value)
        }

        BarText {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            color: Theme.text2
            font.pixelSize: 11
        }

        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: Theme.radiusRow
            color: root.expandable && expandArea.containsMouse ? Theme.hover : "transparent"

            Icon {
                anchors.centerIn: parent
                visible: root.expandable
                text: root.expanded ? Icons.chevronUp : Icons.chevronDown
                color: Theme.muted
                font.pixelSize: 14
            }

            MouseArea {
                id: expandArea
                anchors.fill: parent
                enabled: root.expandable
                hoverEnabled: true
                onClicked: root.expandToggled()
            }
        }
    }
}
