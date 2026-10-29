import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.common
import qs.widgets

// The session's polkit agent (replaces hyprpolkitagent): asks for a password when an app needs
// elevated rights (pkexec, systemctl, udisks, ...), on the monitor that was focused at the time.
// Enter authenticates, Escape cancels. A wrong password keeps the dialog open for another try.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow
    // Set when the request arrives, so the window opens on that screen and stays there.
    property bool open: false
    property string screenName: ""
    // A response was sent and PAM hasn't asked again or finished yet.
    property bool checking: false
    property bool wrongPassword: false

    readonly property bool canSubmit: flow !== null && flow.isResponseRequired && !checking
    readonly property string statusText: {
        const message = flow?.supplementaryMessage ?? "";
        // pam_unix reports nothing on a wrong password, but e.g. faillock explains itself.
        if (wrongPassword)
            return flow?.supplementaryIsError && message !== "" ? message : "Wrong password, try again";
        return message;
    }
    readonly property bool statusIsError: wrongPassword || (flow?.supplementaryIsError ?? false)

    function submit(response: string) {
        checking = true;
        wrongPassword = false;
        flow.submit(response);
    }

    function cancel() {
        flow?.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.screenName = Hyprland.focusedMonitor?.name ?? "";
            root.checking = false;
            root.wrongPassword = false;
            root.open = true;
        }
        // Completed, cancelled here or withdrawn by the requesting app.
        onIsActiveChanged: {
            if (!isActive)
                root.open = false;
        }
    }

    Connections {
        target: root.flow

        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired)
                root.checking = false;
        }

        // The flow restarts its PAM session by itself and asks again.
        function onAuthenticationFailed() {
            root.checking = false;
            root.wrongPassword = true;
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                id: content

                anchors.fill: parent
                opacity: 0

                function submitInput() {
                    if (!root.canSubmit || input.text === "")
                        return;
                    const response = input.text;
                    input.text = "";
                    root.submit(response);
                }

                Component.onCompleted: {
                    opacity = 1;
                    input.forceActiveFocus();
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                // Escape from the field or anywhere else in the dialog.
                Keys.onEscapePressed: root.cancel()

                Connections {
                    target: root.flow

                    function onAuthenticationFailed() {
                        input.text = "";
                        shakeAnimation.restart();
                        input.forceActiveFocus();
                    }
                }

                // Takes stray clicks (they shouldn't cancel the request) and keeps the keys in the field.
                MouseArea {
                    anchors.fill: parent
                    onClicked: input.forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.tint(Theme.ground, 0.6)
                }

                Plate {
                    id: card

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round((parent.height - height) / 2)
                    width: 420
                    height: column.implicitHeight + 24

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "black"
                        shadowOpacity: 0.35
                        shadowBlur: 1
                        shadowVerticalOffset: 8
                    }

                    // Rises into place as it fades in; x shakes on a wrong password.
                    transform: Translate {
                        id: shake

                        y: 8 * (1 - content.opacity)
                    }

                    SequentialAnimation {
                        id: shakeAnimation

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: -8
                            duration: 50
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: 6
                            duration: 70
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: 0
                            duration: 80
                            easing.type: Easing.OutQuad
                        }
                    }

                    ColumnLayout {
                        id: column

                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: Theme.radiusRow
                                color: Theme.inset

                                Icon {
                                    anchors.centerIn: parent
                                    text: Icons.shieldLock
                                    color: Theme.gilt
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                BarText {
                                    Layout.fillWidth: true
                                    text: root.flow?.message ?? ""
                                    font.pixelSize: 13
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                }

                                BarText {
                                    Layout.fillWidth: true
                                    text: root.flow?.actionId ?? ""
                                    color: Theme.text2
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        // Whose password to give, when polkit accepts more than one admin.
                        Rectangle {
                            visible: identities.count > 1
                            Layout.fillWidth: true
                            implicitHeight: identityColumn.implicitHeight + 8
                            radius: Theme.radiusInset
                            color: Theme.inset

                            ColumnLayout {
                                id: identityColumn

                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

                                Repeater {
                                    id: identities

                                    model: root.flow?.identities ?? []

                                    ListRow {
                                        id: identityRow

                                        required property var modelData

                                        Layout.fillWidth: true
                                        icon: modelData.isGroup ? Icons.accountGroup : Icons.account
                                        label: modelData.displayName
                                        sublabel: modelData.isGroup ? "Group" : ""
                                        active: root.flow?.selectedIdentity === modelData
                                        onClicked: {
                                            if (root.flow && !identityRow.active) {
                                                // Restarts PAM for the new identity; drop what was typed for the old one.
                                                input.text = "";
                                                root.checking = false;
                                                root.wrongPassword = false;
                                                root.flow.selectedIdentity = identityRow.modelData;
                                            }
                                            input.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: Theme.radiusRow
                                color: Theme.inset
                                border.width: 1
                                border.color: root.wrongPassword ? Theme.alert : input.activeFocus ? Theme.gilt : Theme.rule

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.durationState
                                        easing.type: Theme.easing
                                    }
                                }

                                Icon {
                                    id: fieldIcon

                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Icons.lock
                                    color: root.wrongPassword ? Theme.alert : Theme.muted
                                    font.pixelSize: 14
                                }

                                TextInput {
                                    id: input

                                    anchors.left: fieldIcon.right
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                    // Read-only rather than disabled: a disabled item drops keyboard focus.
                                    readOnly: root.checking
                                    color: Theme.text
                                    selectionColor: Theme.selection
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    clip: true
                                    onAccepted: content.submitInput()

                                    BarText {
                                        anchors.fill: parent
                                        visible: input.text === ""
                                        // PAM prompts end in a colon ("Password: "). The field is emptied on submit,
                                        // so this also shows the wait for PAM's answer.
                                        text: root.checking ? "Checking…" : (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                                        color: Theme.muted
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            BarText {
                                visible: root.statusText !== ""
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                text: root.statusText
                                color: root.statusIsError ? Theme.alert : Theme.text2
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                            }

                            DialogButton {
                                label: "Cancel"
                                onClicked: root.cancel()
                            }

                            DialogButton {
                                label: "Authenticate"
                                primary: true
                                enabled: root.canSubmit && input.text !== ""
                                onClicked: content.submitInput()
                            }
                        }
                    }
                }
            }
        }
    }

    component DialogButton: Rectangle {
        id: button

        property string label
        property bool primary: false

        signal clicked

        implicitWidth: Math.max(88, buttonLabel.implicitWidth + 28)
        implicitHeight: 32
        radius: Theme.radiusInset
        color: primary ? (buttonArea.containsMouse ? Theme.giltHover : Theme.gilt) : buttonArea.containsMouse ? Theme.hover : "transparent"
        border.width: primary ? 0 : 1
        border.color: Theme.rule
        opacity: enabled ? 1 : 0.5

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationState
            }
        }

        BarText {
            id: buttonLabel

            anchors.centerIn: parent
            text: button.label
            color: button.primary ? Theme.ground : Theme.text
            font.pixelSize: 12
            font.bold: button.primary
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
