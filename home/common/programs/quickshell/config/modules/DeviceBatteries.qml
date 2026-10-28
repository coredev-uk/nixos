import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Small battery chips for wireless peripherals, two per row. Hidden when there are none.
// `shown`: whether the containing panel is open; polling only runs while one is.
GridLayout {
    id: root

    property bool shown: false
    property bool holding: false

    function sync() {
        if (shown === holding)
            return;
        holding = shown;
        shown ? Batteries.acquire() : Batteries.release();
    }

    onShownChanged: sync()
    Component.onCompleted: sync()
    // The panel's view Loader destroys this when switching to a sub-view.
    Component.onDestruction: {
        if (holding)
            Batteries.release();
    }

    columns: 2
    columnSpacing: 4
    rowSpacing: 4
    visible: Batteries.devices.length > 0

    Repeater {
        model: Batteries.devices

        Rectangle {
            id: chip

            required property var modelData
            readonly property bool known: modelData.level !== null
            readonly property real level: known ? modelData.level : 0
            readonly property color accent: !known ? Theme.overlay0 : level > 50 ? Theme.green : level > 20 ? Theme.yellow : Theme.red

            Layout.fillWidth: true
            Layout.preferredWidth: 1 // equal columns
            implicitHeight: row.implicitHeight + 14
            radius: 8
            color: Theme.surface0

            HoverHandler {
                id: hover
            }

            // Full name ("Razer Viper V3 Pro (…)") whenever the chip shows less of it: the
            // brand is dropped from the label and long names are elided.
            Tooltip {
                anchorItem: chip
                text: chip.modelData.name
                active: hover.hovered && (nameLabel.truncated || chip.modelData.short !== chip.modelData.name)
            }

            RowLayout {
                id: row
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                CircularProgress {
                    implicitWidth: 24
                    implicitHeight: 24
                    value: chip.level
                    color: chip.accent
                    icon: {
                        switch (chip.modelData.kind) {
                        case "headset":
                            return Icons.headphones;
                        case "mouse":
                            return Icons.mouse;
                        case "keyboard":
                            return Icons.keyboard;
                        default:
                            return Icons.battery;
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    BarText {
                        id: nameLabel
                        Layout.fillWidth: true
                        text: chip.modelData.short
                        font.pixelSize: 11
                        color: Theme.subtext0
                        elide: Text.ElideRight
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: !chip.known ? "Off" : `${chip.level}%${chip.modelData.charging ? " · Charging" : ""}`
                        font.pixelSize: 12
                        font.bold: true
                        color: chip.known ? Theme.text : Theme.overlay0
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
