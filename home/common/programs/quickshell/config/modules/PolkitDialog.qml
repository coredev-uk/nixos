import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.common
import qs.widgets

// Session polkit agent: asks for a password when an app needs elevated rights (pkexec, systemctl,
// udisks, ...), on the monitor focused at the time. Enter authenticates, Escape cancels; a wrong
// password keeps the dialog open.
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
    // pam_u2f (hosts/common/desktop/default.nix) waits for a touch without asking for anything,
    // after its cue: the field says so instead of asking for a password. The password follows
    // if the key isn't touched.
    readonly property bool awaitingKey: flow !== null && !flow.isResponseRequired && !checking && !(flow.supplementaryIsError ?? false) && (flow.supplementaryMessage ?? "") !== ""
    readonly property string statusText: {
        const message = flow?.supplementaryMessage ?? "";
        // pam_unix reports nothing on a wrong password, but e.g. faillock explains itself.
        if (wrongPassword)
            return flow?.supplementaryIsError && message !== "" ? message : "Wrong password, try again";
        // Information is about the wait it came with (the key's cue, shown in the field); once a
        // password is asked for, it's stale. Errors stay.
        return flow?.supplementaryIsError ? message : "";
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

        // Two layers: no_screen_share (hyprland/default.nix) blacks out a layer's full box in a
        // screen share, so only the card's layer carries it and a share shows the dimmed screen
        // around a card-sized black box. The scrim is declared first so it maps under the card.
        Scope {
            id: layers

            readonly property ShellScreen targetScreen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]

            PanelWindow {
                screen: layers.targetScreen
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: Theme.tint(Theme.ground, 0.6)
                WlrLayershell.namespace: "polkit-scrim"
                WlrLayershell.layer: WlrLayer.Overlay

                // Takes stray clicks: they shouldn't cancel the request. Keys stay with the card's layer.
                MouseArea {
                    anchors.fill: parent
                }
            }

            PanelWindow {
                id: window

                // Room around the card for its shadow and shake.
                readonly property int shadowPadding: 24

                screen: layers.targetScreen
                // No anchors: the compositor centres the layer on the screen.
                exclusionMode: ExclusionMode.Ignore
                implicitWidth: card.width + shadowPadding * 2
                implicitHeight: card.height + shadowPadding * 2
                color: "transparent"
                // The shadow takes no clicks: they land on the scrim.
                mask: Region {
                    item: card
                }
                WlrLayershell.namespace: "polkit"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                // Hyprland fades the layers in and out (animations.nix).
                Item {
                    id: content

                    anchors.fill: parent

                    function submitInput() {
                        if (!root.canSubmit || input.text === "")
                            return;
                        const response = input.text;
                        input.text = "";
                        root.submit(response);
                    }

                    Component.onCompleted: input.forceActiveFocus()

                    Keys.onEscapePressed: root.cancel()

                    Connections {
                        target: root.flow

                        function onAuthenticationFailed() {
                            input.text = "";
                            shakeAnimation.restart();
                            input.forceActiveFocus();
                        }
                    }

                    // Clicks on the card outside its controls keep the keys in the field.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: input.forceActiveFocus()
                    }

                    Plate {
                        id: card

                        x: window.shadowPadding
                        y: window.shadowPadding
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

                        // Rises the last few pixels into place as Hyprland fades the layer in; x
                        // shakes on a wrong password.
                        transform: Translate {
                            id: shake

                            y: 8

                            Behavior on y {
                                NumberAnimation {
                                    duration: Theme.durationState
                                    easing.type: Theme.easing
                                }
                            }
                        }

                        Component.onCompleted: shake.y = 0

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
                                        // A badge for the dialog, not a state: gilt is kept for here and on.
                                        color: Theme.text2
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
                                        text: root.awaitingKey ? Icons.key : Icons.lock
                                        color: root.wrongPassword ? Theme.alert : root.checking || root.awaitingKey ? Theme.text2 : Theme.muted
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
                                            text: root.checking ? "Checking…" : root.awaitingKey ? root.flow.supplementaryMessage : (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                                            // text2: the field has no label of its own, and "Checking…" is a status.
                                            color: Theme.text2
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
    }
}
