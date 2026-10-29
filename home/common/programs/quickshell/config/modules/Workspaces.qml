import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

// This monitor's workspaces as numerals. The active one is gilt over a 2px gilt rule while its
// monitor has focus (you are here), and enamel over a muted rule on the other screen.
Row {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.monitor === root.monitor && !ws.name.startsWith("special:")).sort((a, b) => a.id - b.id)

        Item {
            id: workspace

            required property HyprlandWorkspace modelData
            readonly property bool here: modelData.active && (root.monitor?.focused ?? false)

            implicitWidth: Math.max(22, label.implicitWidth + 10)
            implicitHeight: Theme.barHeight

            BarText {
                id: label
                anchors.centerIn: parent
                text: workspace.modelData.name
                color: workspace.here ? Theme.gilt : workspace.modelData.active || area.containsMouse ? Theme.text : Theme.text2
                font.bold: workspace.modelData.active
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: Theme.barAtTop ? undefined : parent.top
                anchors.bottom: Theme.barAtTop ? parent.bottom : undefined
                width: 14
                height: 2
                visible: workspace.modelData.active
                color: workspace.here ? Theme.gilt : Theme.muted
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                onClicked: workspace.modelData.activate()
            }
        }
    }
}
