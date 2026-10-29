import QtQuick
import Quickshell
import qs.common
import qs.widgets

// Suspend, restart and shut down as plate-toned buttons, shown with the password. Each runs only
// after being held for a moment, so a stray click can't power the machine off: its armed hue
// (caution for restart, alert for shut down, as in the bar's power menu) grows from the centre
// while held. Hovering names the button in a tooltip above it.
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
        accent: Theme.caution
        command: ["systemctl", "reboot"]
    }

    HoldButton {
        icon: Icons.power
        label: "Shut down"
        accent: Theme.alert
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
        radius: Math.round(Theme.radiusInset * root.s)
        color: area.containsMouse ? Theme.tint(Theme.hover, 0.9) : Theme.tint(Theme.plate, 0.85)
        border.width: 1
        border.color: Theme.rule
        scale: area.pressed ? 0.94 : 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: button.radius
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
        Plate {
            id: tooltip

            readonly property bool shown: area.pressed || hoverDelay.passed

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: Math.round(12 * root.s)
            width: tip.implicitWidth + Math.round(28 * root.s)
            height: Math.round(36 * root.s)
            radius: Math.round(Theme.radiusRow * root.s)
            opacity: shown ? 1 : 0
            visible: opacity > 0

            transform: Translate {
                y: tooltip.shown ? 0 : Math.round(6 * root.s)

                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
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
            easing.type: Theme.easing
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
