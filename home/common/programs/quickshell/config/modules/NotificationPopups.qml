pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import qs.services

// Notification popups in the corner under the bar on the focused monitor, newest next to the
// bar. Each leaves after its timeout (paused while hovered) but stays in the centre. Cards slide
// in from the screen edge and back out to it, and the rest of the stack closes up behind them;
// Hyprland leaves this layer alone (no_anim) so the motion is only this.
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
    // Mapped until the last card has finished leaving.
    visible: NotificationService.popups.length > 0 || leave.running
    // The full height of the screen, so the stack never clips as cards come and go; only the
    // cards take input.
    anchors {
        top: true
        bottom: true
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
    mask: Region {
        item: list.contentItem
    }
    color: "transparent"
    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only an inline reply needs the keyboard, and then only once clicked.
    WlrLayershell.keyboardFocus: NotificationService.popups.some(entry => entry.notification.hasInlineReply) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    ListView {
        id: list

        anchors.fill: parent
        spacing: 8
        interactive: false
        verticalLayoutDirection: Theme.barAtTop ? ListView.TopToBottom : ListView.BottomToTop
        model: ScriptModel {
            values: NotificationService.popups
        }

        // One thing at a time, so cards never cross: the stack makes room and the new card
        // follows it in; a leaving card goes first and the stack closes up after it.
        add: Transition {
            SequentialAnimation {
                PropertyAction {
                    property: "opacity"
                    value: 0
                }
                PropertyAction {
                    property: "x"
                    value: 24
                }
                PauseAnimation {
                    duration: Theme.durationState / 2
                }
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                    NumberAnimation {
                        property: "x"
                        to: 0
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }
        }
        remove: Transition {
            id: leave

            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Theme.durationExit
                easing.type: Theme.easingExit
            }
            NumberAnimation {
                property: "x"
                to: 24
                duration: Theme.durationExit
                easing.type: Theme.easingExit
            }
        }
        addDisplaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }
        removeDisplaced: Transition {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.durationExit
                }
                NumberAnimation {
                    property: "y"
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }

        delegate: NotificationCard {
            id: card

            required property QtObject modelData

            entry: modelData
            floating: true
            width: list.width

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
