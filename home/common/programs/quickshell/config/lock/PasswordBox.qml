import QtQuick
import qs.common
import qs.widgets

// Password field: a hidden TextInput takes the keys (it keeps focus even while the card is hidden,
// so the first key typed on the idle clock lands here), the field draws one dot per character.
// Every screen's box mirrors the shared LockContext text, whichever one has keyboard focus.
Rectangle {
    id: root

    required property LockContext context
    // Layout scale from the surface (1 at 1080p).
    property real s: 1

    readonly property bool hasError: context.statusIsError && context.statusText !== ""

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: Math.round(52 * s)
    radius: Math.round(16 * s)
    color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.85)
    border.width: Math.max(1, Math.round(2 * s))
    border.color: hasError ? Theme.red : context.capsLock ? Theme.yellow : context.currentText !== "" ? Theme.blue : "transparent"

    Behavior on border.color {
        ColorAnimation {
            duration: 180
        }
    }

    transform: Translate {
        id: shake
    }

    SequentialAnimation {
        id: shakeAnimation

        NumberAnimation {
            target: shake
            property: "x"
            to: -12 * root.s
            duration: 50
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: shake
            property: "x"
            to: 10 * root.s
            duration: 70
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: shake
            property: "x"
            to: -6 * root.s
            duration: 70
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: shake
            property: "x"
            to: 0
            duration: 90
            easing.type: Easing.OutQuad
        }
    }

    Connections {
        target: root.context

        function onFailuresChanged() {
            shakeAnimation.restart();
        }

        function onCurrentTextChanged() {
            if (input.text !== root.context.currentText)
                input.text = root.context.currentText;
        }
    }

    TextInput {
        id: input

        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        // Read-only rather than disabled: a disabled item drops keyboard focus.
        readOnly: root.context.checking || root.context.unlocking
        onTextChanged: root.context.currentText = text
        onAccepted: {
            root.context.activate();
            root.context.tryUnlock();
        }

        Keys.onEscapePressed: root.context.cancel()
        Keys.onPressed: event => {
            const t = event.text;
            if (t.length === 1 && t.toLowerCase() !== t.toUpperCase()) {
                const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                root.context.capsLock = (t === t.toUpperCase()) !== shift;
            }
            event.accepted = false;
        }
    }

    // Square tile on the left, like the field's "key".
    Rectangle {
        id: lockTile

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(6 * root.s)
        width: height
        radius: root.radius - anchors.margins
        color: root.hasError ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2) : Theme.surface1

        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }

        Icon {
            anchors.centerIn: parent
            text: Icons.lock
            color: root.hasError ? Theme.red : Theme.subtext1
            font.pixelSize: Math.round(18 * root.s)
        }
    }

    BarText {
        anchors.centerIn: parent
        text: "Enter password"
        color: Theme.overlay0
        font.pixelSize: Math.round(15 * root.s)
        opacity: root.context.currentText === "" && !root.context.checking ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    // Between the tile and the submit button. A fixed row of slots that fill and empty in place: an
    // integer Repeater model sized to the text would rebuild every dot on each keystroke. Each slot's
    // width animates, so the centred row slides smoothly as dots come and go.
    Item {
        id: dotArea

        readonly property real dotSize: Math.round(10 * root.s)
        readonly property real step: dotSize + Math.round(8 * root.s)

        anchors.left: lockTile.right
        anchors.right: submit.left
        anchors.leftMargin: Math.round(10 * root.s)
        anchors.rightMargin: Math.round(10 * root.s)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        Row {
            id: dots

            anchors.verticalCenter: parent.verticalCenter
            x: (dotArea.width - width) / 2

            Repeater {
                // Longer passwords just keep the field full.
                model: Math.max(1, Math.floor(dotArea.width / dotArea.step))

                Item {
                    id: slot

                    required property int index
                    readonly property bool filled: index < root.context.currentText.length

                    width: filled ? dotArea.step : 0
                    height: dotArea.dotSize

                    Behavior on width {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: dotArea.dotSize
                        height: width
                        radius: width / 2
                        color: Theme.text
                        opacity: slot.filled ? 1 : 0
                        scale: slot.filled ? 1 : 0.4

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            // Pulses while PAM checks the password.
            SequentialAnimation on opacity {
                running: root.context.checking
                loops: Animation.Infinite
                onStopped: dots.opacity = 1

                NumberAnimation {
                    to: 0.35
                    duration: 450
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1
                    duration: 450
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Rectangle {
        id: submit

        readonly property bool shown: root.context.currentText !== "" && !root.context.checking

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(6 * root.s)
        width: height
        radius: lockTile.radius
        color: submitArea.containsMouse ? Qt.lighter(Theme.blue, 1.1) : Theme.blue
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
            }
        }

        Icon {
            anchors.centerIn: parent
            text: Icons.arrowRight
            color: Theme.crust
            font.pixelSize: Math.round(20 * root.s)
        }

        MouseArea {
            id: submitArea

            anchors.fill: parent
            enabled: submit.shown
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.context.tryUnlock()
        }
    }
}
