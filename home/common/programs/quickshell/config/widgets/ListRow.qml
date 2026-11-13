import QtQuick
import QtQuick.Layouts
import qs.common

// Selectable row in the panel sub-views (wifi networks, VPN countries, bluetooth devices, power
// actions, lighting looks). Transparent at rest, hover on hover; active or armed rows tint in
// their accent (gilt: connected, selected) and take it on the glyph and label. A swatch (the
// colours a lighting look puts on, blended left to right) takes the glyph's place and keeps its
// own colours.
Rectangle {
    id: root

    property string icon
    property bool emoji: false
    property string label
    property string sublabel
    property bool active: false
    property color accent: Theme.gilt
    property var swatches: []

    signal clicked

    implicitHeight: row.implicitHeight + 16
    radius: Theme.radiusRow
    color: active ? Theme.tint(accent, area.containsMouse ? 0.16 : 0.1) : area.containsMouse ? Theme.hover : "transparent"
    opacity: enabled ? 1 : 0.5

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 10

        Text {
            Layout.preferredWidth: 20
            text: root.swatches.length > 0 ? "" : root.icon
            // Muted only on a clear row; it sinks into the hover fill, so it lifts to text2 there.
            color: root.active ? root.accent : area.containsMouse ? Theme.text2 : Theme.muted
            font.family: root.emoji ? Theme.emojiFont : Theme.iconFont
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }

            // A rule ring keeps a dark colour apart from the row under it.
            Rectangle {
                anchors.centerIn: parent
                visible: root.swatches.length > 0
                width: 12
                height: 12
                radius: 6
                color: root.swatches[0] ?? "transparent"
                border.width: 1
                border.color: Theme.rule
                gradient: root.swatches.length > 1 ? blend : null

                Gradient {
                    id: blend
                    orientation: Gradient.Horizontal
                    stops: root.swatches.map((c, i) => stop.createObject(blend, {
                                position: i / (root.swatches.length - 1),
                                color: c
                            }))
                }

                Component {
                    id: stop
                    GradientStop {}
                }
            }
        }

        BarText {
            Layout.fillWidth: true
            text: root.label
            color: root.active ? root.accent : Theme.text
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        BarText {
            text: root.sublabel
            color: Theme.text2
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
