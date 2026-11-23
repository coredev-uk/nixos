import QtQuick
import qs.common
import qs.widgets

// Password line under the time: slate field with a dot per character, gilt submit, and why the
// last attempt failed or Caps Lock. A hidden TextInput takes the keys and keeps focus while idle
// so the first key lands.
Item {
    id: root

    required property AuthContext context
    property real s: 1

    readonly property bool shown: context.active || context.unlocking
    readonly property string message: context.statusText || (context.capsLock ? "Caps Lock is on" : "")
    readonly property color messageColor: context.statusText ? (context.statusIsError ? Theme.alert : Theme.text) : Theme.caution
    readonly property bool failed: context.statusIsError && context.statusText !== ""

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
        radius: Math.round(Theme.radiusInset * root.s)
        // Plate-toned, a little translucent so the softened picture shows through. Edge: gilt while
        // focused, alert after a wrong password, ok once accepted.
        color: Theme.tint(Theme.plate, 0.85)
        border.width: 1
        border.color: root.context.unlocking ? Theme.ok : root.failed ? Theme.alert : input.activeFocus ? Theme.gilt : Theme.rule
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
                        easing.type: Theme.easing
                    }
                }
            }
        ]

        Behavior on opacity {
            NumberAnimation {
                duration: 260
                easing.type: Theme.easing
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: field.padding
            anchors.verticalCenter: parent.verticalCenter
            text: "Enter password"
            color: Theme.text2
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(19 * root.s)
            opacity: root.context.currentText === "" ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }

        // Fixed row of slots filled in place: an integer-sized Repeater model would rebuild every dot per keystroke.
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
                                easing.type: Theme.easing
                            }
                        }

                        Rectangle {
                            width: dotArea.dotSize
                            height: width
                            radius: width / 2
                            color: root.context.unlocking ? Theme.ok : Theme.text
                            opacity: slot.filled ? 1 : 0
                            scale: slot.filled ? 1 : 0.4

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durationState
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Theme.easing
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Theme.easing
                                }
                            }
                        }
                    }
                }

                // Slow, shallow breathing while checking, so a long PAM check reads as waiting.
                SequentialAnimation on opacity {
                    running: root.context.checking
                    loops: Animation.Infinite
                    onStopped: dots.opacity = 1

                    NumberAnimation {
                        to: 0.6
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        Rectangle {
            id: submit

            readonly property bool shown: root.context.currentText !== "" && !root.context.checking && !root.context.unlocking

            anchors.right: parent.right
            anchors.rightMargin: field.inset
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 2 * field.inset
            height: width
            radius: Math.round(Theme.radiusRow * root.s)
            color: submitArea.pressed || submitArea.containsMouse ? Theme.giltHover : Theme.gilt
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.6

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Theme.easing
                }
            }

            Icon {
                anchors.centerIn: parent
                text: Icons.arrowRight
                color: Theme.ground
                font.pixelSize: Math.round(20 * root.s)
            }

            MouseArea {
                id: submitArea

                anchors.fill: parent
                hoverEnabled: true
                enabled: submit.shown
                cursorShape: Qt.PointingHandCursor
                onClicked: root.context.tryUnlock()
            }
        }
    }

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
                duration: Theme.durationState
            }
        }
    }
}
