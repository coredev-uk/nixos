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
    radius: 8
    color: Theme.base

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
            color: Theme.subtext1
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: Theme.surface0
                border.color: input.activeFocus ? Theme.blue : "transparent"
                border.width: 1

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    selectionColor: Theme.surface2
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
                        color: Theme.green,
                        action: () => root.submit()
                    },
                    {
                        icon: Icons.close,
                        color: Theme.red,
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
                    radius: 6
                    color: buttonArea.containsMouse ? Theme.surface1 : Theme.surface0

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
