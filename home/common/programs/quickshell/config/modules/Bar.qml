import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
import qs.widgets

PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        left: true
        right: true
        top: Theme.barAtTop
        bottom: !Theme.barAtTop
    }
    implicitHeight: Theme.barHeight
    color: Theme.crust
    // Matched by the hyprland blur layer rule
    WlrLayershell.namespace: "bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Keeps hypridle from dimming/locking while Caffeine is on.
    IdleInhibitor {
        window: bar
        enabled: Caffeine.enabled
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Workspaces {
            screen: bar.screen
        }
        Sep {
            visible: windowTitle.text !== ""
        }
        WindowTitle {
            id: windowTitle
            screen: bar.screen
            Layout.maximumWidth: 400
        }
    }

    Music {
        anchors.centerIn: parent
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        PrivacyIndicators {
            id: privacy
        }
        Sep {
            visible: privacy.visible
        }
        Tray {}
        Sep {}
        SystemStats {}
        Sep {}
        CaffeineButton {}
        NetworkButton {}
        Sep {}
        DateButton {
            clock: clock
        }
        BarText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
        }
        Sep {}
        Notifications {}
        Sep {}
        PowerButton {}
    }
}
