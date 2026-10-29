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

    onOpening: {
        path = [];
        // The popup itself fades in on open; only level changes while open fade the menu.
        levelFade.complete();
    }
    onPathChanged: levelFade.restart()

    dismissible: true
    implicitWidth: Math.min(400, Math.max(200, column.implicitWidth + 12))
    implicitHeight: frame.implicitHeight + gap

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: column.implicitHeight + 12

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            NumberAnimation {
                id: levelFade
                target: column
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.durationState
                easing.type: Theme.easing
            }

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
                        color: Theme.rule
                    }

                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        radius: Theme.radiusRow
                        color: area.containsMouse && entry.modelData.enabled ? Theme.hover : "transparent"
                        opacity: entry.modelData.enabled ? 1 : 0.5

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.durationState
                                easing.type: Theme.easing
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationState
                                easing.type: Theme.easing
                            }
                        }

                        RowLayout {
                            id: row
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Icon {
                                visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                text: entry.radio ? (entry.checked ? Icons.radioOn : Icons.radioOff) : (entry.checked ? Icons.checkboxOn : Icons.checkboxOff)
                                // Muted sinks into the hover fill, so an unchecked box lifts to text2 there.
                                color: entry.checked ? Theme.gilt : area.containsMouse ? Theme.text2 : Theme.muted
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
                                color: entry.modelData.enabled ? Theme.text : Theme.muted
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Icon {
                                visible: entry.modelData.hasChildren
                                text: Icons.chevronRight
                                color: area.containsMouse ? Theme.text2 : Theme.muted
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
