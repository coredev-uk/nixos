import QtQuick
import Quickshell
import qs.common
import qs.widgets

// Suspend, restart and shut down as flat round buttons, shown with the password. Each runs only
// after being held for a moment, so a stray click can't power the machine off: a disc of its
// colour grows from the centre while held. Hovering names the button in a tooltip above it.
Row {
    id: root

    property real s: 1

    spacing: Math.round(12 * s)

    HoldButton {
        icon: Icons.sleep
        label: "Suspend"
        command: ["systemctl", "suspend"]
    }

    HoldButton {
        icon: Icons.restart
        label: "Restart"
        command: ["systemctl", "reboot"]
    }

    HoldButton {
        icon: Icons.power
        label: "Shut down"
        accent: Theme.red
        command: ["systemctl", "poweroff"]
    }

    component HoldButton: Rectangle {
        id: button

        property string icon
        property string label
        property color accent: Theme.text
        property var command
        property real progress: 0

        width: Math.round(52 * root.s)
        height: width
        radius: width / 2
        color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.24 : 0.14)
        scale: area.pressed ? 0.94 : 1

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: width / 2
            color: button.accent
            opacity: 0.5
            scale: button.progress
        }

        Icon {
            anchors.centerIn: parent
            text: button.icon
            color: Theme.text
            font.pixelSize: Math.round(22 * root.s)
        }

        // Above the button: its name on hover, the instruction while pressed.
        Rectangle {
            id: tooltip

            readonly property bool shown: area.pressed || hoverDelay.passed

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: Math.round(12 * root.s)
            width: tip.implicitWidth + Math.round(28 * root.s)
            height: Math.round(36 * root.s)
            radius: height / 2
            color: Theme.base
            opacity: shown ? 1 : 0
            visible: opacity > 0

            transform: Translate {
                y: tooltip.shown ? 0 : Math.round(6 * root.s)

                Behavior on y {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                id: tip

                anchors.centerIn: parent
                text: area.pressed ? `Hold to ${button.label.toLowerCase()}` : button.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(16 * root.s)
                font.weight: Font.Medium
            }
        }

        Timer {
            id: hoverDelay

            property bool passed: false

            interval: 250
            running: area.containsMouse && !passed
            onTriggered: passed = true
        }

        NumberAnimation {
            id: fill

            target: button
            property: "progress"
            to: 1
            duration: 900
            onFinished: {
                if (button.progress >= 1) {
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
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (!containsMouse)
                    hoverDelay.passed = false;
            }
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
