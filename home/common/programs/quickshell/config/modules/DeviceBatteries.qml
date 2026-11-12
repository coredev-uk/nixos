import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// The wireless peripherals' batteries in the control panel's Devices section, one 32px row each on
// the slider rows' columns: the device's glyph, its name, a 64px level track and the level. Level
// reports only when it needs attention: at 25% or below (not charging) the glyph becomes the
// battery-alert one and the level turns caution (alert at 10%), so it never rests on colour alone;
// charging is "on", the charging glyph in gilt. A switched-off device reads "Off" with an empty
// track. Hidden when there are none. `shown`: whether the panel is open; the levels are read every
// minute while one is.
ColumnLayout {
    id: root

    property bool shown: false
    property bool holding: false

    function sync() {
        if (shown === holding)
            return;
        holding = shown;
        shown ? Batteries.acquire() : Batteries.release();
    }

    function glyphOf(kind: string): string {
        switch (kind) {
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

    onShownChanged: sync()
    Component.onCompleted: sync()
    // The panel's section Loader destroys this when another section is chosen.
    Component.onDestruction: {
        if (holding)
            Batteries.release();
    }

    visible: Batteries.devices.length > 0
    spacing: 0

    SectionLabel {
        Layout.topMargin: 8
        text: "Batteries"
    }

    Repeater {
        model: Batteries.devices

        RowLayout {
            id: device

            required property var modelData
            readonly property bool known: modelData.level !== null
            readonly property real level: known ? modelData.level : 0
            readonly property bool charging: known && modelData.charging
            readonly property bool low: known && !charging && level <= 25
            readonly property color levelColor: !known ? Theme.text2 : low ? (level <= 10 ? Theme.alert : Theme.caution) : Theme.text2

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.preferredHeight: 32
            spacing: 10

            Icon {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignHCenter
                text: device.charging ? Icons.batteryCharging : device.low ? Icons.batteryAlert : root.glyphOf(device.modelData.kind)
                color: device.charging ? Theme.gilt : device.low ? device.levelColor : device.known ? Theme.text2 : Theme.muted
            }

            BarText {
                Layout.fillWidth: true
                text: device.modelData.short
                color: device.known ? Theme.text : Theme.text2
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: 64
                implicitHeight: 4
                radius: 2
                color: Theme.inset

                Rectangle {
                    width: Math.round(Math.min(device.level, 100) / 100 * parent.width)
                    height: parent.height
                    radius: 2
                    color: device.low ? device.levelColor : Theme.fill
                }
            }

            BarText {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: device.known ? `${device.level}%` : "Off"
                color: device.levelColor
                font.pixelSize: 11
            }
        }
    }
}
