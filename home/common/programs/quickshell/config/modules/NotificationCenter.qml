pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.services
import qs.widgets

// Notification history under the bell: every notification not yet dismissed, newest first.
BarPopup {
    id: root

    // Opened over IPC (a key binding) the bar has had no input, which the popup grab needs, so
    // Hyprland drops it at once; Hyprland's focus grab does the dismissing instead.
    property bool fromIpc: false

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
                    values: NotificationService.entries
                }
                delegate: NotificationCard {
                    required property QtObject modelData

                    width: list.width - (list.ScrollBar.vertical.visible ? 10 : 0)
                    entry: modelData
                    // The clock only paces it: its date is the start of the minute.
                    now: {
                        clock.date;
                        return Date.now();
                    }
                    bodyLines: 8
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
