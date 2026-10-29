import QtQuick
import QtQuick.Layouts
import qs.common

// Inline password entry: Enter or the check button submits, the cross cancels.
Rectangle {
    id: root

    property string title

    signal submitted(string password)
    signal cancelled

    function submit() {
        if (input.text === "")
            return;
        const password = input.text;
        input.text = "";
        root.submitted(password);
    }

    implicitHeight: column.implicitHeight + 16
    radius: Theme.radiusInset
    color: Theme.inset

    onVisibleChanged: {
        input.text = "";
        if (visible)
            input.forceActiveFocus();
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        BarText {
            Layout.fillWidth: true
            text: root.title
            color: Theme.text2
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.radiusRow
                color: Theme.plate
                border.color: input.activeFocus ? Theme.gilt : Theme.rule
                border.width: 1

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    selectionColor: Theme.selection
                    selectedTextColor: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    clip: true
                    onAccepted: root.submit()
                }
            }

            Repeater {
                model: [
                    {
                        icon: Icons.check,
                        color: Theme.ok,
                        action: () => root.submit()
                    },
                    {
                        icon: Icons.close,
                        color: Theme.alert,
                        action: () => {
                            input.text = "";
                            root.cancelled();
                        }
                    }
                ]

                Rectangle {
                    required property var modelData

                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Theme.radiusRow
                    color: buttonArea.containsMouse ? Theme.hover : Theme.plate
                    border.color: Theme.rule
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        text: parent.modelData.icon
                        color: parent.modelData.color
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: buttonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: parent.modelData.action()
                    }
                }
            }
        }
    }
}
