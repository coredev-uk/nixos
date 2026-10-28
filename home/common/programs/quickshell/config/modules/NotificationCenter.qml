pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.services
import qs.widgets

// Notification history under the bell: every notification not yet dismissed, grouped by app.
// Groups are ordered by their newest notification, newest first inside; a group of several is a
// stack of its newest card that expands on click.
BarPopup {
    id: root

    // Opened over IPC (a key binding) the bar has had no input, which the popup grab needs, so
    // Hyprland drops it at once; Hyprland's focus grab does the dismissing instead.
    property bool fromIpc: false
    // Apps whose stack is expanded, by name. Dropped once an app is down to one notification, so
    // its next stack starts collapsed.
    property var expandedApps: []
    // App names, in the order of their newest notification (entries are newest first).
    readonly property var apps: [...new Set(NotificationService.entries.map(entry => NotificationService.appName(entry.notification)))]

    function entriesOf(app: string): var {
        return NotificationService.entries.filter(entry => NotificationService.appName(entry.notification) === app);
    }

    function setExpanded(app: string, expanded: bool) {
        const others = expandedApps.filter(other => other !== app);
        expandedApps = expanded ? [...others, app] : others;
    }

    function toggleFromIpc() {
        if (!visible)
            fromIpc = true;
        toggle();
    }

    implicitWidth: 440
    implicitHeight: frame.implicitHeight + gap
    dismissible: !fromIpc

    onVisibleChanged: {
        if (!visible)
            fromIpc = false;
    }

    HyprlandFocusGrab {
        active: root.fromIpc && root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    Connections {
        target: NotificationService

        function onEntriesChanged() {
            const kept = root.expandedApps.filter(app => root.entriesOf(app).length > 1);
            if (kept.length !== root.expandedApps.length)
                root.expandedApps = kept;
        }
    }

    SystemClock {
        id: clock

        enabled: root.visible
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: content.implicitHeight + 24
        radius: 12
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 6

                BarText {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.pixelSize: 13
                    font.bold: true
                }

                HeaderButton {
                    icon: NotificationService.dnd ? Icons.bellOff : Icons.bell
                    label: "Do not disturb"
                    active: NotificationService.dnd
                    onClicked: NotificationService.toggleDnd()
                }

                HeaderButton {
                    visible: NotificationService.count > 0
                    icon: Icons.notificationClearAll
                    label: "Clear all"
                    onClicked: NotificationService.clearAll()
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 140
                visible: NotificationService.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Icons.bellOutline
                        color: Theme.overlay0
                        font.pixelSize: 32
                    }

                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No notifications"
                        color: Theme.subtext0
                        font.pixelSize: 12
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 600)
                visible: NotificationService.count > 0
                clip: true
                spacing: 6
                ScrollBar.vertical: ListScrollBar {}
                model: ScriptModel {
                    values: root.apps
                }
                delegate: Item {
                    id: group

                    required property string modelData
                    readonly property var entries: root.entriesOf(modelData)
                    readonly property bool expanded: entries.length > 1 && root.expandedApps.includes(modelData)
                    // Cards peeking out below a collapsed stack, at most two. Kept off the empty
                    // group a delegate briefly holds on its way out.
                    readonly property int layers: expanded ? 0 : Math.max(0, Math.min(entries.length - 1, 2))
                    // Only expanding and collapsing animate the height, not cards coming and going.
                    property bool animating: false

                    function setExpanded(expanded: bool) {
                        animating = true;
                        settle.restart();
                        root.setExpanded(modelData, expanded);
                    }

                    width: list.width - (list.ScrollBar.vertical.visible ? 10 : 0)
                    implicitHeight: cards.implicitHeight + 5 * layers
                    clip: animating

                    Behavior on implicitHeight {
                        enabled: group.animating

                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Timer {
                        id: settle

                        interval: 250
                        onTriggered: group.animating = false
                    }

                    // Behind the newest card, which is the only one shown while collapsed.
                    Repeater {
                        model: group.layers

                        Rectangle {
                            required property int index

                            x: 8 * (index + 1)
                            y: cards.implicitHeight - height + 5 * (index + 1)
                            z: -index
                            width: group.width - 2 * x
                            height: 24
                            radius: 8
                            color: Qt.tint(Theme.base, Qt.alpha(Theme.mantle, 0.4 + 0.3 * index))
                            border.color: Qt.alpha(Theme.surface0, 0.8 - 0.3 * index)
                            border.width: 1
                        }
                    }

                    Column {
                        id: cards

                        width: parent.width
                        spacing: 6

                        RowLayout {
                            width: parent.width
                            visible: group.expanded
                            spacing: 6

                            BarText {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                text: group.modelData
                                color: Theme.subtext0
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            HeaderButton {
                                icon: Icons.chevronUp
                                label: "Show less"
                                onClicked: group.setExpanded(false)
                            }

                            HeaderButton {
                                icon: Icons.notificationClearAll
                                label: "Clear"
                                onClicked: NotificationService.clearApp(group.modelData)
                            }
                        }

                        Repeater {
                            model: ScriptModel {
                                values: group.entries
                            }

                            NotificationCard {
                                required property QtObject modelData
                                required property int index

                                width: group.width
                                visible: index === 0 || group.expanded
                                entry: modelData
                                // The clock only paces it: its date is the start of the minute.
                                now: {
                                    clock.date;
                                    return Date.now();
                                }
                                bodyLines: 8
                                stacked: index === 0 && !group.expanded ? group.entries.length - 1 : 0
                                onExpand: group.setExpanded(true)
                            }
                        }

                        add: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                        move: Transition {
                            NumberAnimation {
                                property: "y"
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: button

        property string icon
        property string label
        property bool active: false

        signal clicked

        implicitWidth: buttonRow.implicitWidth + 16
        implicitHeight: 28
        radius: 6
        color: active ? Qt.alpha(Theme.peach, 0.1) : buttonArea.containsMouse ? Theme.surface0 : "transparent"

        Row {
            id: buttonRow

            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: button.icon
                color: button.active ? Theme.peach : Theme.overlay0
                font.pixelSize: 14
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: button.label
                color: button.active ? Theme.peach : Theme.text
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
