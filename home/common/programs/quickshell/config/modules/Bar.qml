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
    color: Theme.ground
    WlrLayershell.namespace: "bar"

    // Keeps hypridle from dimming/locking while Caffeine is on.
    IdleInhibitor {
        window: bar
        enabled: Caffeine.enabled
    }

    // The 1px rule along the bar's inner edge.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: Theme.barAtTop ? undefined : parent.top
        anchors.bottom: Theme.barAtTop ? parent.bottom : undefined
        height: 1
        color: Theme.rule
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Workspaces {
            screen: bar.screen
        }
        WindowTitle {
            id: windowTitle
            visible: text !== ""
            screen: bar.screen
            Layout.leftMargin: 4
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
        Tray {
            id: tray
        }
        Sep {
            visible: tray.visible
        }
        SystemStats {}
        Sep {}
        CaffeineButton {}
        NetworkButton {}
        Sep {}
        Clock {}
        Sep {}
        Notifications {}
        Sep {}
        PowerButton {}
    }
}
