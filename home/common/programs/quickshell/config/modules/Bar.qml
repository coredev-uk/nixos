import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.widgets

PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.crust
    // Matched by the hyprland blur layer rule
    WlrLayershell.namespace: "bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Workspaces {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Music {
        anchors.centerIn: parent
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Tray {}
        Sep {}
        SystemStats {}
        Sep {}
        NetworkButton {
            bar: bar
        }
        Sep {}
        Brightness {}
        Volume {}
        Sep {}
        DateButton {
            bar: bar
            clock: clock
        }
        BarText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
        }
        Sep {}
        Notifications {}
    }
}
