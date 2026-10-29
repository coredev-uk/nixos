import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.widgets

// This monitor's workspaces as numerals. The active one is gilt over a 2px gilt rule while its
// monitor has focus (you are here), and enamel over a muted rule on the other screen. The rule
// is one index that glides to the new numeral as Hyprland slides the workspace in, in the same
// time on the same curve (home/common/desktop/hyprland/config/animations.nix).
Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    property Item activeItem: null
    // Off until the index has first taken its place, so it doesn't glide in from the left edge.
    property bool glide: false

    function updateActive() {
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item?.modelData.active) {
                activeItem = item;
                if (!glide)
                    Qt.callLater(() => root.glide = true);
                return;
            }
        }
        activeItem = null;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row

        Repeater {
            id: repeater

            model: ScriptModel {
                values: Hyprland.workspaces.values.filter(ws => ws.monitor === root.monitor && !ws.name.startsWith("special:")).sort((a, b) => a.id - b.id)
            }

            onItemAdded: Qt.callLater(root.updateActive)
            // At once, while the leaving numeral still exists, so the index never loses its place.
            onItemRemoved: root.updateActive()

            Item {
                id: workspace

                required property HyprlandWorkspace modelData
                readonly property bool active: modelData.active
                readonly property bool here: active && (root.monitor?.focused ?? false)

                implicitWidth: Math.max(22, label.implicitWidth + 10)
                implicitHeight: Theme.barHeight

                onActiveChanged: Qt.callLater(root.updateActive)

                BarText {
                    id: label
                    anchors.centerIn: parent
                    text: workspace.modelData.name
                    color: workspace.here ? Theme.gilt : workspace.active || area.containsMouse ? Theme.text : Theme.text2
                    font.bold: workspace.active
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: workspace.modelData.activate()
                }
            }
        }
    }

    Rectangle {
        id: index

        anchors.top: Theme.barAtTop ? undefined : parent.top
        anchors.bottom: Theme.barAtTop ? parent.bottom : undefined
        width: 14
        height: 2
        visible: root.activeItem !== null
        color: (root.activeItem?.here ?? false) ? Theme.gilt : Theme.muted

        // Keeps its last place while no numeral is active, so the next one is a glide, not a jump
        // from the left edge.
        Binding {
            target: index
            property: "x"
            when: root.activeItem !== null
            value: root.activeItem ? root.activeItem.x + Math.round((root.activeItem.width - index.width) / 2) : 0
            restoreMode: Binding.RestoreNone
        }

        Behavior on x {
            enabled: root.glide

            NumberAnimation {
                duration: Theme.durationSwitch
                easing.type: Theme.easing
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationSwitch
                easing.type: Theme.easing
            }
        }
    }
}
