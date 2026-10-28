import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.common
import qs.widgets

// Session actions. Log out, reboot, the Windows ones and shut down need a second click to confirm.
// Windows comes from the VFIO module (hosts/common/services/vfio.nix): its VM with the GPU passed
// through (which ends this session) and a reboot straight into Windows, each shown when its
// command is on PATH.
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
            id: "windows",
            label: "Restart to Windows",
            icon: Icons.windows,
            color: Theme.sapphire,
            confirm: true,
            confirmLabel: "Click again for Windows",
            command: "vfio-boot-native",
            run: () => Quickshell.execDetached(["vfio-boot-native"])
        },
        {
            id: "windowsVm",
            label: "Windows VM",
            icon: Icons.monitor,
            color: Theme.teal,
            confirm: true,
            confirmLabel: "Click again to start the VM",
            command: "vfio-start-vm",
            run: () => Quickshell.execDetached(["vfio-start-vm"])
        },
        {
            id: "poweroff",
            label: "Shut down",
            icon: Icons.power,
            color: Theme.red,
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        }
    ].filter(action => !action.command || commands.includes(action.command))

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

                ListRow {
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
        }
    }
}
