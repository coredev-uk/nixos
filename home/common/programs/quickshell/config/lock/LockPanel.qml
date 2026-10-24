import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.widgets

// The active face: a card that pops up with the user and password field, then widens on both sides
// to show its side panels (TimeWing left, StatusWing right). On unlock the side panels close and
// the card folds away.
Item {
    id: root

    required property AuthContext context
    property real s: 1

    readonly property real coreWidth: Math.round(440 * s)
    readonly property real wingWidth: Math.round(360 * s)
    readonly property real cardHeight: Math.round(470 * s)
    readonly property real pad: Math.round(24 * s)

    property real centerReveal: 0
    property real wingsReveal: 0
    property real fold: 1

    readonly property string avatarPath: Quickshell.env("QS_LOCK_AVATAR") ?? ""
    readonly property string displayName: root.context.user.charAt(0).toUpperCase() + root.context.user.slice(1)

    function focusInput() {
        password.focusInput();
    }

    Connections {
        target: root.context

        function onActiveChanged() {
            if (root.context.unlocking)
                return;
            closeAnimation.stop();
            openAnimation.stop();
            (root.context.active ? openAnimation : closeAnimation).start();
        }

        function onUnlockingChanged() {
            if (!root.context.unlocking)
                return;
            openAnimation.stop();
            closeAnimation.stop();
            outroAnimation.start();
        }
    }

    SequentialAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "centerReveal"
            to: 1
            duration: 200
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
        NumberAnimation {
            target: root
            property: "wingsReveal"
            to: 1
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "wingsReveal"
            to: 0
            duration: 120
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "centerReveal"
            to: 0
            duration: 160
            easing.type: Easing.InQuad
        }
    }

    // Fits inside AuthContext's outro delay.
    SequentialAnimation {
        id: outroAnimation

        NumberAnimation {
            target: root
            property: "wingsReveal"
            to: 0
            duration: 120
            easing.type: Easing.InQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "fold"
                to: 0
                duration: 220
                easing.type: Easing.InBack
                easing.overshoot: 1.3
            }
            NumberAnimation {
                target: root
                property: "centerReveal"
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.52 - height / 2) + (root.context.active ? 0 : Math.round(60 * root.s))
        width: root.coreWidth + (root.context.hasUserSession ? root.wingsReveal * 2 * root.wingWidth : 0)
        height: root.cardHeight
        radius: Math.round(28 * root.s)
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.82)
        clip: true
        opacity: root.centerReveal
        scale: 0.92 + 0.08 * root.centerReveal
        // No `visible: opacity > 0` here: the password field inside must keep keyboard focus while
        // the card is hidden, so the first key typed on the idle clock reaches it.

        // Only while shown: the shadow pass isn't free, and the card is invisible when idle.
        layer.enabled: opacity > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: 0.35
            shadowBlur: 1
            shadowVerticalOffset: Math.round(8 * root.s)
        }

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: root.fold
            yScale: root.fold
        }

        Behavior on y {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: content

            // Centred, so the card widens evenly on both sides of the core.
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.coreWidth + 2 * root.wingWidth
            height: parent.height

            // The side panels show the user session (notifications, media); none before login.
            Loader {
                active: root.context.hasUserSession
                x: root.pad
                width: root.wingWidth - 2 * root.pad
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: root.pad
                opacity: root.wingsReveal
                transform: Translate {
                    x: (1 - root.wingsReveal) * 30 * root.s
                }

                sourceComponent: TimeWing {
                    s: root.s
                }
            }

            // Core: who is locked out, and the password field.
            Column {
                x: root.wingWidth + root.pad
                width: root.coreWidth - 2 * root.pad
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(14 * root.s)

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(132 * root.s)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: Math.round(3 * root.s)
                    border.color: root.context.unlocking ? Theme.green : Theme.blue

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: Math.round(8 * root.s)
                        radius: width / 2
                        color: Theme.surface0

                        Text {
                            anchors.centerIn: parent
                            visible: avatar.status !== Image.Ready
                            text: root.displayName.charAt(0)
                            color: Theme.blue
                            font.family: Theme.displayFontFamily
                            font.pixelSize: Math.round(52 * root.s)
                            font.weight: Font.Bold
                        }

                        Image {
                            id: avatar

                            anchors.fill: parent
                            source: root.avatarPath !== "" ? `file://${root.avatarPath}` : ""
                            sourceSize.width: parent.width * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.displayName
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(24 * root.s)
                    font.weight: Font.DemiBold
                }

                // Status pill: locked / checking / errors / caps lock / welcome.
                Rectangle {
                    id: status

                    readonly property bool isError: root.context.statusIsError && root.context.statusText !== ""
                    readonly property color tone: root.context.unlocking ? Theme.green : isError ? Theme.red : root.context.checking ? Theme.peach : root.context.capsLock ? Theme.yellow : Theme.subtext0

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: statusRow.implicitWidth + Math.round(28 * root.s)
                    height: Math.round(30 * root.s)
                    radius: height / 2
                    color: Qt.rgba(tone.r, tone.g, tone.b, 0.14)

                    Behavior on width {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Row {
                        id: statusRow

                        anchors.centerIn: parent
                        spacing: Math.round(8 * root.s)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(7 * root.s)
                            height: width
                            radius: width / 2
                            color: status.tone
                        }

                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.context.unlocking ? "Welcome back" : root.context.checking ? "Checking…" : root.context.statusText || (root.context.capsLock ? "Caps Lock is on" : root.context.idleStatus)
                            color: status.tone
                            font.pixelSize: Math.round(13 * root.s)
                            font.weight: Font.Medium
                        }
                    }
                }

                Item {
                    width: 1
                    height: Math.round(6 * root.s)
                }

                PasswordBox {
                    id: password

                    width: parent.width
                    context: root.context
                    s: root.s
                }
            }

            Loader {
                active: root.context.hasUserSession
                x: root.wingWidth + root.coreWidth + root.pad
                width: root.wingWidth - 2 * root.pad
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: root.pad
                opacity: root.wingsReveal
                transform: Translate {
                    x: -(1 - root.wingsReveal) * 30 * root.s
                }
                // Its play/pause button stays unclickable while the panel is hidden.
                enabled: root.wingsReveal > 0.99

                sourceComponent: StatusWing {
                    s: root.s
                }
            }
        }
    }
}
