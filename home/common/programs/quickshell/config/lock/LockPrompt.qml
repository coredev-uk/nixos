import QtQuick
import qs.common
import qs.widgets

// The password, in the line under the time: a flat round field with a dot per typed character
// and a solid round submit on its right, and beside it why the last attempt failed or that Caps
// Lock is on. Shown while the context is active. A hidden TextInput takes the keys and keeps
// focus while idle, so the first key typed lands.
Item {
    id: root

    required property AuthContext context
    // Layout scale from the surface (1 at 1080p).
    property real s: 1

    readonly property bool shown: context.active || context.unlocking
    readonly property string message: context.statusText || (context.capsLock ? "Caps Lock is on" : "")
    readonly property color messageColor: context.statusText ? (context.statusIsError ? Theme.red : Theme.text) : Theme.yellow

    function focusInput() {
        input.forceActiveFocus();
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

        width: 1
        height: 1
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

    Rectangle {
        id: field

        readonly property real inset: Math.round(6 * root.s)
        readonly property real padding: Math.round(26 * root.s)

        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(460 * root.s)
        height: parent.height
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.16)
        opacity: root.shown ? 1 : 0
        visible: opacity > 0

        transform: [
            Translate {
                id: shake
            },
            Translate {
                y: root.shown ? 0 : Math.round(16 * root.s)

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        ]

        Behavior on opacity {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: field.padding
            anchors.verticalCenter: parent.verticalCenter
            text: "Enter password"
            color: Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(19 * root.s)
            opacity: root.context.currentText === "" ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // A fixed row of slots that fill and empty in place: an integer Repeater model sized to
        // the text would rebuild every dot on each keystroke. Each slot's width animates, so the
        // row grows and shrinks smoothly.
        Item {
            id: dotArea

            readonly property real dotSize: Math.round(10 * root.s)
            readonly property real step: dotSize + Math.round(8 * root.s)

            anchors.left: parent.left
            anchors.leftMargin: field.padding
            anchors.right: submit.left
            anchors.rightMargin: Math.round(12 * root.s)
            anchors.verticalCenter: parent.verticalCenter
            height: dotSize
            clip: true

            Row {
                id: dots

                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    // Longer passwords just keep the field full.
                    model: Math.max(1, Math.floor(Math.max(0, dotArea.width) / dotArea.step))

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
                            width: dotArea.dotSize
                            height: width
                            radius: width / 2
                            // Green once accepted, for the moment before everything sinks away.
                            color: root.context.unlocking ? Theme.green : Theme.text
                            opacity: slot.filled ? 1 : 0
                            scale: slot.filled ? 1 : 0.4

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

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

                // Pulses while the password is checked.
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

        // Submits, for the mouse; Enter does the same.
        Rectangle {
            id: submit

            readonly property bool shown: root.context.currentText !== "" && !root.context.checking && !root.context.unlocking

            anchors.right: parent.right
            anchors.rightMargin: field.inset
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 2 * field.inset
            height: width
            radius: width / 2
            color: submitArea.pressed ? Theme.subtext1 : Theme.text
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.6

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
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
                cursorShape: Qt.PointingHandCursor
                onClicked: root.context.tryUnlock()
            }
        }
    }

    // Why the last attempt failed, Caps Lock, or what PAM says.
    Text {
        anchors.left: field.right
        anchors.leftMargin: Math.round(28 * root.s)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.message
        color: root.messageColor
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(19 * root.s)
        font.weight: Font.Medium
        opacity: root.context.active && !root.context.unlocking && root.message !== "" ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }
    }
}
