import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.widgets

// Themed tray item menu; submenus open in place with a back row.
BarPopup {
    id: root

    required property QsMenuHandle menu
    // Submenu entries opened from the root menu, innermost last.
    property var path: []
    readonly property QsMenuHandle current: path.length > 0 ? path[path.length - 1] : menu

    onOpening: path = []

    dismissible: true
    implicitWidth: Math.min(400, Math.max(200, column.implicitWidth + 12))
    implicitHeight: frame.implicitHeight + gap

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: column.implicitHeight + 12
        radius: 10
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            BackButton {
                visible: root.path.length > 0
                title: root.path.length > 0 ? root.current.text : ""
                onClicked: root.path = root.path.slice(0, -1)
            }

            Repeater {
                model: opener.children

                Item {
                    id: entry

                    required property QsMenuEntry modelData
                    readonly property bool radio: modelData.buttonType === QsMenuButtonType.RadioButton
                    readonly property bool checked: modelData.checkState === Qt.Checked

                    Layout.fillWidth: true
                    implicitWidth: row.implicitWidth + 20
                    implicitHeight: modelData.isSeparator ? 9 : row.implicitHeight + 12

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.surface0
                    }

                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        radius: 6
                        color: area.containsMouse && entry.modelData.enabled ? Theme.surface0 : "transparent"
                        opacity: entry.modelData.enabled ? 1 : 0.5

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Icon {
                                visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                text: entry.radio ? (entry.checked ? Icons.radioOn : Icons.radioOff) : (entry.checked ? Icons.checkboxOn : Icons.checkboxOff)
                                color: entry.checked ? Theme.blue : Theme.overlay0
                                font.pixelSize: 14
                            }

                            IconImage {
                                visible: entry.modelData.icon !== ""
                                source: entry.modelData.icon
                                implicitSize: 16
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: entry.modelData.text
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Icon {
                                visible: entry.modelData.hasChildren
                                text: Icons.chevronRight
                                color: Theme.overlay0
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: entry.modelData.enabled
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    root.path = [...root.path, entry.modelData];
                                } else {
                                    entry.modelData.triggered();
                                    root.visible = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
