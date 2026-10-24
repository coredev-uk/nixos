import QtQuick
import Quickshell
import qs.common
import qs.widgets

// Bottom-right power button, shown with the password card. Its menu's actions run only after being
// held for a moment, so a stray click on the lock screen can't power the machine off.
Item {
    id: root

    required property LockContext context
    property real s: 1

    property bool menuOpen: false

    anchors.fill: parent

    Connections {
        target: root.context

        function onActiveChanged() {
            if (!root.context.active)
                root.menuOpen = false;
        }
    }

    Rectangle {
        id: toggle

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(32 * root.s)
        width: Math.round(52 * root.s)
        height: width
        radius: Math.round(16 * root.s)
        color: toggleArea.containsMouse || root.menuOpen ? Theme.surface1 : Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.82)
        opacity: root.context.active && !root.context.unlocking ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Icon {
            anchors.centerIn: parent
            text: root.menuOpen ? Icons.close : Icons.power
            color: root.menuOpen ? Theme.text : Theme.red
            font.pixelSize: Math.round(22 * root.s)
        }

        MouseArea {
            id: toggleArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    Rectangle {
        id: menu

        anchors.right: toggle.right
        anchors.bottom: toggle.top
        anchors.bottomMargin: Math.round(14 * root.s)
        width: Math.round(280 * root.s)
        height: root.menuOpen ? actions.implicitHeight + 2 * Math.round(12 * root.s) : 0
        radius: Math.round(20 * root.s)
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.9)
        clip: true
        opacity: root.menuOpen ? 1 : 0
        visible: height > 0

        Behavior on height {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: actions

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(12 * root.s)
            spacing: Math.round(8 * root.s)

            HoldButton {
                icon: Icons.sleep
                label: "Suspend"
                accent: Theme.mauve
                command: ["systemctl", "suspend"]
            }

            HoldButton {
                icon: Icons.restart
                label: "Restart"
                accent: Theme.blue
                command: ["systemctl", "reboot"]
            }

            HoldButton {
                icon: Icons.power
                label: "Shut down"
                accent: Theme.red
                command: ["systemctl", "poweroff"]
            }
        }
    }

    // Fills with its accent while held; runs the command when full, drains if let go early.
    component HoldButton: Rectangle {
        id: button

        property string icon
        property string label
        property color accent
        property var command
        property real progress: 0

        width: parent.width
        height: Math.round(48 * root.s)
        radius: Math.round(14 * root.s)
        color: holdArea.containsMouse ? Theme.surface1 : Theme.surface0
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * button.progress
            radius: parent.radius
            color: Qt.rgba(button.accent.r, button.accent.g, button.accent.b, 0.35)
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Math.round(16 * root.s)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(14 * root.s)

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: button.icon
                color: button.accent
                font.pixelSize: Math.round(20 * root.s)
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: holdArea.pressed ? `Hold to ${button.label.toLowerCase()}…` : button.label
                font.pixelSize: Math.round(15 * root.s)
                font.weight: Font.Medium
            }
        }

        NumberAnimation {
            id: fill

            target: button
            property: "progress"
            to: 1
            duration: 900
            onFinished: {
                if (button.progress >= 1) {
                    root.menuOpen = false;
                    button.progress = 0;
                    Quickshell.execDetached(button.command);
                }
            }
        }

        NumberAnimation {
            id: drain

            target: button
            property: "progress"
            to: 0
            duration: 250
            easing.type: Easing.OutCubic
        }

        MouseArea {
            id: holdArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                drain.stop();
                // Resume from wherever an earlier, released hold drained to.
                fill.duration = 900 * (1 - button.progress);
                fill.restart();
            }
            onReleased: {
                if (button.progress < 1) {
                    fill.stop();
                    drain.restart();
                }
            }
            onCanceled: {
                fill.stop();
                drain.restart();
            }
        }
    }
}
