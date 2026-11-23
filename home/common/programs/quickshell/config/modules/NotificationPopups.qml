pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import qs.services

// Popups in the corner under the bar on the focused monitor, newest next to the bar. Each leaves
// after its timeout (paused on hover) but stays in the centre. Cards slide in from the screen edge
// and back out, the stack closing up behind; Hyprland leaves this layer alone (no_anim).
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
    // Only as tall as the stack: Hyprland blacks out the whole surface in screen shares
    // (no_screen_share), so a full-height window showed as a black strip down the screen. It grows
    // with a new card at once, and shrinks (or unmaps, after the last) once a leaving card and the
    // stack closing up behind it are done. Not on the remove Transition's `running`: it starts after
    // the height drops and can stay true for good, which kept the window mapped.
    property real stackHeight: 0
    visible: NotificationService.popups.length > 0 || stackHeight > 0
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
    implicitHeight: Math.max(1, stackHeight)
    mask: Region {
        item: list.contentItem
    }
    color: "transparent"
    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only an inline reply needs the keyboard, once clicked.
    WlrLayershell.keyboardFocus: NotificationService.popups.some(entry => entry.notification.hasInlineReply) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Timer {
        id: shrink

        interval: Theme.durationExit * 2 + Theme.durationState
        onTriggered: root.stackHeight = list.contentHeight
    }

    ListView {
        id: list

        // Every card exists however short the window is, so contentHeight is the whole stack's.
        cacheBuffer: 4000
        onContentHeightChanged: {
            if (contentHeight >= root.stackHeight) {
                root.stackHeight = contentHeight;
                shrink.stop();
            } else {
                shrink.restart();
            }
        }

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
            countdown: expiry.interval > 0
            // Full again while hovered; leaving restarts the timeout.
            onHoveredChanged: {
                if (hovered)
                    refill.restart();
            }

            NumberAnimation {
                id: refill

                target: card
                property: "timeLeft"
                to: 1
                duration: Theme.durationState
                easing.type: Theme.easing
            }

            Timer {
                id: expiry

                interval: card.notification ? root.timeout(card.notification) : 0
                running: interval > 0 && !card.hovered
                onTriggered: NotificationService.hidePopup(card.entry)
            }

            // Countdown track, in step with the timer.
            NumberAnimation {
                id: drain

                target: card
                property: "timeLeft"
                from: 1
                to: 0
                duration: expiry.interval
                running: expiry.running
            }

            // A replacement shows for a full timeout again.
            Connections {
                target: card.entry

                function onTimeChanged() {
                    if (expiry.running) {
                        expiry.restart();
                        drain.restart();
                    }
                }
            }
        }
    }
}
