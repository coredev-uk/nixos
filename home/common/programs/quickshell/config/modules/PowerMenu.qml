import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

// Session actions. Log out, reboot and shut down need a second click to confirm.
BarPopup {
    id: root

    // Action awaiting confirmation.
    property string pending: ""

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            icon: Icons.lock,
            color: Theme.blue,
            confirm: false,
            // hypridle's lock_cmd starts hyprlock on lock-session.
            run: () => Quickshell.execDetached(["loginctl", "lock-session"])
        },
        {
            id: "suspend",
            label: "Suspend",
            icon: Icons.sleep,
            color: Theme.mauve,
            confirm: false,
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            id: "logout",
            label: "Log out",
            icon: Icons.logout,
            color: Theme.yellow,
            confirm: true,
            run: () => Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit")
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: Icons.restart,
            color: Theme.peach,
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            id: "poweroff",
            label: "Shut down",
            icon: Icons.power,
            color: Theme.red,
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        }
    ]

    function activate(action: var) {
        if (action.confirm && pending !== action.id) {
            pending = action.id;
            return;
        }
        pending = "";
        visible = false;
        action.run();
    }

    onVisibleChanged: pending = ""

    dismissible: true
    implicitWidth: 220
    implicitHeight: frame.implicitHeight + gap

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: column.implicitHeight + 12
        radius: 12
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: root.actions

                ListRow {
                    required property var modelData
                    readonly property bool armed: root.pending === modelData.id

                    Layout.fillWidth: true
                    icon: modelData.icon
                    label: armed ? `Click again to ${modelData.label.toLowerCase()}` : modelData.label
                    active: armed
                    accent: modelData.color
                    onClicked: root.activate(modelData)
                }
            }
        }
    }
}
