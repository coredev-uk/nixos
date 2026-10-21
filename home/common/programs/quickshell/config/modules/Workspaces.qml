import QtQuick
import Quickshell.Hyprland
import qs.common
import qs.widgets

Row {
    spacing: 10

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => !ws.name.startsWith("special:")).sort((a, b) => a.id - b.id)

        Icon {
            required property HyprlandWorkspace modelData

            text: modelData.focused ? Icons.workspaceActive : Icons.workspace
            color: modelData.focused ? Theme.pink : Theme.surface2
        }
    }
}
