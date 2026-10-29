import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

// Title of the focused window, shown on the focused monitor's bar (HyprlandToplevel.monitor isn't
// populated until Hyprland reports the window's details, so match on the focused monitor instead).
BarText {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    text: monitor !== null && Hyprland.focusedMonitor === monitor ? (Hyprland.activeToplevel?.title ?? "") : ""
    color: Theme.text2
    elide: Text.ElideRight
}
