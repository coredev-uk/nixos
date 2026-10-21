import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

PopupWindow {
    id: root

    required property Item anchorItem
    required property PanelWindow bar

    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()

    function toggle() {
        const now = new Date();
        month = now.getMonth();
        year = now.getFullYear();
        visible = !visible;
    }

    function shiftMonth(delta: int) {
        const date = new Date(year, month + delta, 1);
        month = date.getMonth();
        year = date.getFullYear();
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    visible: false
    color: "transparent"
    implicitWidth: 350
    implicitHeight: frame.implicitHeight + 8

    HyprlandFocusGrab {
        windows: [root, root.bar]
        active: root.visible
        onCleared: root.visible = false
    }

    component NavButton: Rectangle {
        id: button

        property alias icon: label.text

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: 6
        color: area.containsMouse ? Theme.surface0 : "transparent"

        Icon {
            id: label
            anchors.centerIn: parent
            color: Theme.lavender
            font.pixelSize: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    Rectangle {
        id: frame
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: content.implicitHeight + 32
        radius: 12
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                NavButton {
                    icon: Icons.chevronLeft
                    onClicked: root.shiftMonth(-1)
                }

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                    color: Theme.lavender
                    font.pixelSize: 13
                    font.bold: true
                }

                NavButton {
                    icon: Icons.chevronRight
                    onClicked: root.shiftMonth(1)
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: grid.locale
                delegate: BarText {
                    required property string shortName

                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.lavender
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            MonthGrid {
                id: grid
                Layout.fillWidth: true
                month: root.month
                year: root.year
                delegate: Rectangle {
                    id: day

                    required property var model

                    implicitWidth: 40
                    implicitHeight: 32
                    radius: 6
                    color: model.today ? Theme.pink : "transparent"

                    BarText {
                        anchors.centerIn: parent
                        text: day.model.day
                        color: day.model.today ? Theme.base : day.model.month === grid.month ? Theme.text : Theme.surface2
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
