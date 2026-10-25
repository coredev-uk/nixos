import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Coloured glyphs for whatever is being captured right now (macOS colours: orange microphone,
// green camera, purple screen); hidden when nothing is. Click lists the apps.
Item {
    id: root

    readonly property var categories: [
        {
            key: "camera",
            label: "Camera",
            icon: Icons.webcam,
            color: Theme.green
        },
        {
            key: "microphone",
            label: "Microphone",
            icon: Icons.microphone,
            color: Theme.peach
        },
        {
            key: "screen",
            label: "Screen sharing",
            icon: Icons.monitorShare,
            color: Theme.mauve
        },
        {
            key: "systemAudio",
            label: "System audio",
            icon: Icons.waveform,
            color: Theme.red
        }
    ]
    readonly property var activeCategories: categories.filter(category => Privacy[category.key].length > 0)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    // Stay mapped while the last glyph fades out.
    visible: Privacy.active || linger.running

    Connections {
        target: Privacy
        function onActiveChanged() {
            if (!Privacy.active) {
                linger.restart();
                popup.visible = false;
            }
        }
    }

    Timer {
        id: linger
        interval: 200
    }

    Row {
        id: row
        spacing: 6

        Repeater {
            model: root.categories

            Icon {
                required property var modelData
                readonly property bool shown: Privacy[modelData.key].length > 0

                visible: shown || opacity > 0
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.6
                text: modelData.icon
                color: modelData.color

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.toggle()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !popup.visible
        text: root.activeCategories.map(category => `${category.label} — ${Privacy[category.key].map(app => app.name).join(", ")}`).join("\n")
    }

    BarPopup {
        id: popup

        anchorItem: root
        dismissible: true
        implicitWidth: 260
        implicitHeight: frame.implicitHeight + gap

        Rectangle {
            id: frame
            anchors.fill: parent
            anchors.topMargin: popup.topInset
            anchors.bottomMargin: popup.bottomInset
            implicitHeight: content.implicitHeight + 24
            radius: 12
            color: Theme.mantle
            border.color: Theme.surface0
            border.width: 1

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: root.activeCategories

                    Rectangle {
                        id: card

                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: apps.implicitHeight + 16
                        radius: 8
                        color: Theme.base

                        ColumnLayout {
                            id: apps
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            RowLayout {
                                Layout.leftMargin: 4
                                Layout.bottomMargin: 2
                                spacing: 8

                                Icon {
                                    Layout.preferredWidth: 20
                                    text: card.modelData.icon
                                    color: card.modelData.color
                                }

                                BarText {
                                    Layout.fillWidth: true
                                    text: card.modelData.label
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: Privacy[card.modelData.key]

                                RowLayout {
                                    id: app

                                    required property var modelData

                                    Layout.leftMargin: 4
                                    spacing: 8

                                    Item {
                                        implicitWidth: 20
                                        implicitHeight: 20

                                        IconImage {
                                            anchors.centerIn: parent
                                            visible: app.modelData.icon !== ""
                                            source: app.modelData.icon
                                            implicitSize: 16
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            visible: app.modelData.icon === ""
                                            text: Icons.application
                                            color: Theme.overlay0
                                        }
                                    }

                                    BarText {
                                        Layout.fillWidth: true
                                        text: app.modelData.name
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
