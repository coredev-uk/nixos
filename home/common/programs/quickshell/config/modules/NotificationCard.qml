pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// One notification, as a popup (`floating`) or a card in the centre's list. Clicking it runs the
// default action (NotificationService.activate); the cross dismisses it everywhere.
Plate {
    id: root

    // A NotificationService entry. Null for a moment once dismissed, before the delegate goes.
    required property QtObject entry
    property bool floating: false
    // For the relative time; the centre ticks it, popups are always recent.
    property double now: Date.now()
    property int bodyLines: 4
    // How many more of the app's notifications sit collapsed behind this one in the centre: shown
    // as a badge, and clicking the card asks to expand them instead of running its action.
    property int stacked: 0

    signal expand

    readonly property Notification notification: entry?.notification ?? null
    readonly property bool hovered: hover.hovered
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property bool hasDefault: notification?.actions.some(action => action.identifier === "default") ?? false
    readonly property var buttons: notification?.actions.filter(action => action.identifier !== "default") ?? []
    // A picture sent with the notification wins over the app's icon.
    readonly property string imageSource: source(notification?.image ?? "")
    readonly property DesktopEntry desktopEntry: DesktopEntries.byId(notification?.desktopEntry ?? "")
    readonly property string iconSource: source(notification?.appIcon ?? "") || source(desktopEntry?.icon ?? "")
    // Groups inside the card sit a tone step away from its background: inset on a popup's plate,
    // plate on a centre card's inset.
    readonly property color inner: floating ? Theme.inset : Theme.plate
    readonly property color innerHover: floating ? Theme.rule : Theme.hover

    // Paths, URLs (file://, image:// for pixel data) or icon theme names.
    function source(image: string): string {
        if (image === "")
            return "";
        if (image.startsWith("/"))
            return `file://${image}`;
        if (image.includes("://"))
            return image;
        return Quickshell.iconPath(image, true);
    }

    function relativeTime(ms: double): string {
        const minutes = Math.floor(ms / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes}m`;
        const hours = Math.floor(minutes / 60);
        return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
    }

    implicitHeight: column.implicitHeight + 24
    radius: floating ? Theme.radiusPlate : Theme.radiusInset
    color: floating ? Theme.plate : Theme.inset
    border.width: floating || critical ? 1 : 0
    border.color: critical ? Theme.alert : Theme.rule

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.hasDefault || root.stacked > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.stacked > 0)
                root.expand();
            else
                NotificationService.activate(root.entry);
        }
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                Layout.alignment: Qt.AlignTop
                visible: root.imageSource !== "" || root.iconSource !== ""
                implicitWidth: 64
                implicitHeight: 64
                radius: Theme.radiusInset
                color: "transparent"

                Image {
                    anchors.fill: parent
                    visible: root.imageSource !== ""
                    source: root.imageSource
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: root.imageSource === ""
                    implicitSize: 48
                    source: root.iconSource
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    BarText {
                        Layout.fillWidth: true
                        text: `${NotificationService.appName(root.notification)} · ${root.relativeTime(root.now - (root.entry?.time ?? root.now))}`
                        color: root.critical ? Theme.alert : Theme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.stacked > 0
                        implicitWidth: moreText.implicitWidth + 12
                        implicitHeight: 18
                        radius: Theme.radiusRow
                        color: root.inner

                        BarText {
                            id: moreText

                            anchors.centerIn: parent
                            text: `${root.stacked} more`
                            color: Theme.text2
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: Theme.radiusRow
                        color: closeArea.containsMouse ? root.innerHover : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            text: Icons.close
                            color: closeArea.containsMouse ? Theme.text : Theme.muted
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: closeArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.notification?.dismiss()
                        }
                    }
                }

                BarText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification?.summary ?? ""
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                BarText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    color: Theme.text2
                    linkColor: Theme.link
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: root.bodyLines
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    HoverHandler {
                        cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : undefined
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.buttons.length > 0
            spacing: 6

            Repeater {
                model: root.buttons

                Rectangle {
                    id: button

                    required property NotificationAction modelData

                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Theme.radiusRow
                    color: buttonArea.containsMouse ? root.innerHover : root.inner

                    // With action icons the identifier is an icon name and the text only a label.
                    IconImage {
                        anchors.centerIn: parent
                        visible: root.notification?.hasActionIcons ?? false
                        implicitSize: 16
                        source: visible ? Quickshell.iconPath(button.modelData.identifier, true) : ""
                    }

                    BarText {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        visible: !(root.notification?.hasActionIcons ?? false)
                        text: button.modelData.text
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: buttonArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: button.modelData.invoke()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.notification?.hasInlineReply ?? false
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.radiusRow
                color: root.inner
                border.color: reply.activeFocus ? Theme.gilt : Theme.rule
                border.width: 1

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                TextInput {
                    id: reply

                    function send() {
                        if (text === "")
                            return;
                        root.notification.sendInlineReply(text);
                        text = "";
                    }

                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.selection
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    clip: true
                    onAccepted: send()

                    BarText {
                        anchors.fill: parent
                        visible: reply.text === ""
                        text: root.notification?.inlineReplyPlaceholder || "Reply"
                        color: Theme.muted
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: Theme.radiusRow
                color: sendArea.containsMouse ? root.innerHover : root.inner
                // Nothing to send yet.
                opacity: reply.text === "" ? 0.5 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    text: Icons.send
                    color: Theme.gilt
                    font.pixelSize: 14
                }

                MouseArea {
                    id: sendArea

                    enabled: reply.text !== ""

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: reply.send()
                }
            }
        }
    }
}
