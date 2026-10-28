import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common
import qs.widgets

// Session actions, then Windows in a section of its own. Log out, reboot, shut down and both
// Windows ones need a second click to confirm. The Windows ones come from the VFIO module
// (hosts/common/services/vfio.nix): a reboot into Windows, or the same install in a VM with the
// GPU passed through while Linux keeps running underneath; each shown when its command is on PATH.
BarPopup {
    id: root

    // Action awaiting confirmation.
    property string pending: ""
    // The Windows commands found on PATH.
    property var commands: []

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            icon: Icons.lock,
            color: Theme.blue,
            confirm: false,
            // hypridle's lock_cmd starts quickshell-lock (lockscreen.qml) on lock-session.
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

    readonly property var windowsActions: [
        {
            id: "windows",
            label: "Restart into Windows",
            icon: Icons.restart,
            color: Theme.sapphire,
            confirm: true,
            confirmLabel: "Click again to restart",
            command: "vfio-boot-native",
            run: () => Quickshell.execDetached(["vfio-boot-native"])
        },
        {
            id: "windowsVm",
            label: "Open in a VM",
            icon: Icons.monitor,
            color: Theme.teal,
            confirm: true,
            confirmLabel: "Click again to open",
            command: "vfio-start-vm",
            run: () => Quickshell.execDetached(["vfio-start-vm"])
        }
    ].filter(action => commands.includes(action.command))

    Process {
        running: true
        command: ["sh", "-c", "for c in vfio-boot-native vfio-start-vm; do command -v \"$c\" >/dev/null && echo \"$c\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.commands = text.split("\n").filter(line => line)
        }
    }

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

                ActionRow {}
            }

            // The Windows section, under a rule and its own heading.
            Rectangle {
                visible: root.windowsActions.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Theme.surface0
            }

            BarText {
                visible: root.windowsActions.length > 0
                Layout.leftMargin: 12
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                text: "Windows"
                color: Theme.subtext0
                font.pixelSize: 11
            }

            Repeater {
                model: root.windowsActions

                ActionRow {}
            }
        }
    }

    component ActionRow: ListRow {
        required property var modelData
        readonly property bool armed: root.pending === modelData.id

        Layout.fillWidth: true
        icon: modelData.icon
        label: armed ? modelData.confirmLabel ?? `Click again to ${modelData.label.toLowerCase()}` : modelData.label
        active: armed
        accent: modelData.color
        onClicked: root.activate(modelData)
    }
}
