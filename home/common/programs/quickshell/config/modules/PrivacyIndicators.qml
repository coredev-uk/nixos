import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Alert glyphs for anything being captured or cast; one colour for every kind. Hidden when idle.
// Clicking the screen-sharing glyph re-opens the share picker to change what the share shows;
// any other click lists the apps.
Item {
    id: root

    readonly property var categories: [
        {
            key: "camera",
            label: "Camera",
            icon: Icons.webcam
        },
        {
            key: "microphone",
            label: "Microphone",
            icon: Icons.microphone
        },
        {
            key: "screen",
            label: "Screen sharing",
            icon: Icons.monitorShare
        },
        {
            key: "systemAudio",
            label: "System audio",
            icon: Icons.waveform
        },
        {
            key: "cast",
            label: "AirPlay",
            icon: Icons.castConnected,
            // Its entries are speakers, not apps.
            entryIcon: Icons.speakerWireless
        }
    ]
    readonly property var activeCategories: categories.filter(category => Privacy[category.key].length > 0)

    // Key of the shown glyph nearest x (in the row's coordinates); the click area overhangs the row.
    function glyphAt(x: real): string {
        let nearest = "";
        let distance = Infinity;
        for (let i = 0; i < glyphs.count; i++) {
            const glyph = glyphs.itemAt(i);
            if (!glyph?.shown)
                continue;
            const d = Math.abs(x - (glyph.x + glyph.width / 2));
            if (d < distance) {
                distance = d;
                nearest = glyph.modelData.key;
            }
        }
        return nearest;
    }

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
            id: glyphs

            model: root.categories

            Icon {
                required property var modelData
                readonly property bool shown: Privacy[modelData.key].length > 0

                visible: shown || opacity > 0
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.6
                text: modelData.icon
                color: Theme.alert

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        // One glyph alone is narrower than 24px.
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (root.glyphAt(area.mapToItem(row, mouse.x, mouse.y).x) === "screen") {
                popup.visible = false;
                Privacy.switchScreen();
            } else {
                popup.toggle();
            }
        }
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !popup.visible
        text: root.activeCategories.map(category => `${category.label} — ${Privacy[category.key].map(app => app.name).join(", ")}${category.key === "screen" ? " (click to switch)" : ""}`).join("\n")
    }

    BarPopup {
        id: popup

        anchorItem: root
        dismissible: true
        implicitWidth: 260
        implicitHeight: frame.implicitHeight + gap

        Plate {
            id: frame
            anchors.fill: parent
            anchors.topMargin: popup.topInset
            anchors.bottomMargin: popup.bottomInset
            implicitHeight: content.implicitHeight + 24

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
                        radius: Theme.radiusInset
                        color: Theme.inset

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
                                    color: Theme.alert
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
                                            text: card.modelData.entryIcon ?? Icons.application
                                            color: Theme.muted
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
