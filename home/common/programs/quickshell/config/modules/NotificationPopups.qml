pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import qs.services

// Notification popups in the corner under the bar on the focused monitor, newest next to the
// bar. Each leaves after its timeout (paused while hovered) but stays in the centre.
PanelWindow {
    id: root

    // Unless the notification sets its own (in ms); critical ones stay until handled.
    function timeout(notification: Notification): int {
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        switch (notification.urgency) {
        case NotificationUrgency.Low:
            return 5000;
        case NotificationUrgency.Critical:
            return 0;
        default:
            return 10000;
        }
    }

    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: NotificationService.popups.length > 0
    anchors {
        top: Theme.barAtTop
        bottom: !Theme.barAtTop
        right: true
    }
    margins {
        top: 8
        bottom: 8
        right: 8
    }
    // Below the bar's exclusive zone, without reserving space of its own.
    exclusiveZone: 0
    implicitWidth: 420
    implicitHeight: column.implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only an inline reply needs the keyboard, and then only once clicked.
    WlrLayershell.keyboardFocus: NotificationService.popups.some(entry => entry.notification.hasInlineReply) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Column {
        id: column

        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel {
                values: Theme.barAtTop ? NotificationService.popups : NotificationService.popups.slice().reverse()
            }

            NotificationCard {
                id: card

                required property QtObject modelData
                // Slides in from the screen edge.
                property real slide: 24

                entry: modelData
                floating: true
                width: column.width
                opacity: 0
                transform: Translate {
                    x: card.slide
                }

                Component.onCompleted: {
                    opacity = 1;
                    slide = 0;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on slide {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: expiry

                    interval: card.notification ? root.timeout(card.notification) : 0
                    running: interval > 0 && !card.hovered
                    onTriggered: NotificationService.hidePopup(card.entry)
                }

                // A replacement shows for a full timeout again.
                Connections {
                    target: card.entry

                    function onTimeChanged() {
                        // Paused while hovered; it starts over on leaving anyway.
                        if (expiry.running)
                            expiry.restart();
                    }
                }
            }
        }
    }
}
