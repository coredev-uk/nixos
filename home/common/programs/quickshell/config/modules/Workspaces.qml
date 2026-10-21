import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

// Workspaces on this bar's monitor; the active one is pink while the monitor has focus.
Row {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    spacing: 10

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.monitor === root.monitor && !ws.name.startsWith("special:")).sort((a, b) => a.id - b.id)

        Icon {
            id: workspace

            required property HyprlandWorkspace modelData

            text: modelData.active ? Icons.workspaceActive : Icons.workspace
            color: !modelData.active ? Theme.surface2 : root.monitor?.focused ? Theme.pink : Theme.subtext0

            MouseArea {
                // Cover half the row spacing on each side so the gaps stay clickable.
                anchors.fill: parent
                anchors.margins: -5
                onClicked: workspace.modelData.activate()
            }
        }
    }
}
