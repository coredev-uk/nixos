import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.widgets

// One thing that can be shared: a still of it, its name, and a line saying where it is. A click
// (or Enter, Space) shares it.
MouseArea {
    id: root

    // A screen or a window's Wayland toplevel; null draws `glyph` instead.
    property var source: null
    property string title: ""
    property string detail: ""
    // An app's icon beside the title.
    property string icon: ""
    property string glyph: Icons.application
    // The frame's shape; stills are letterboxed in it.
    property real aspect: 16 / 10
    // A dashed selection drawn in the frame, for the region tile.
    property bool dashed: false
    // Draw the focus ring: set once the keyboard has been used, so a tile focused on open stays plain.
    property bool keyboard: false
    readonly property bool captured: still.hasContent
    readonly property bool lit: containsMouse || (activeFocus && keyboard)

    signal chosen
    // Tab or Shift+Tab pressed on this tile.
    signal keyboardUsed
    // Focus arrived here, to scroll the tile into view.
    signal reached

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    activeFocusOnTab: true
    implicitHeight: frame.height + 10 + labels.implicitHeight

    onClicked: chosen()
    onActiveFocusChanged: {
        if (activeFocus)
            reached();
    }
    Keys.onPressed: e => {
        // Qt walks the focus chain on Tab before the picker's key handler sees the key.
        if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab)
            keyboardUsed();
        if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
            return;
        e.accepted = true;
        if (!e.isAutoRepeat)
            root.chosen();
    }

    ClippingRectangle {
        id: frame

        width: parent.width
        height: Math.round(width / root.aspect)
        radius: Theme.radiusInset
        color: Theme.inset

        // One frame, taken as the picker opens.
        ScreencopyView {
            id: still

            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            constraintSize: Qt.size(frame.width, frame.height)
            captureSource: root.source
            live: false
            paintCursor: false
            opacity: hasContent ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }

        Shape {
            id: marquee

            visible: root.dashed
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.52)
            height: Math.round(parent.height * 0.5)
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.lit ? Theme.gilt : Theme.muted
                strokeWidth: 2
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 3]
                fillColor: root.lit ? Theme.tint(Theme.gilt, 0.1) : "transparent"
                startX: 1
                startY: 1

                PathLine {
                    x: marquee.width - 1
                    y: 1
                }
                PathLine {
                    x: marquee.width - 1
                    y: marquee.height - 1
                }
                PathLine {
                    x: 1
                    y: marquee.height - 1
                }
                PathLine {
                    x: 1
                    y: 1
                }
            }
        }

        // Nothing to show (no capture yet, or none possible): the app, or the glyph.
        IconImage {
            anchors.centerIn: parent
            visible: !still.hasContent && root.icon !== ""
            implicitSize: 40
            source: root.icon
        }

        Icon {
            anchors.centerIn: parent
            visible: !still.hasContent && root.icon === "" && !root.dashed
            text: root.glyph
            color: Theme.muted
            font.pixelSize: 34
        }
    }

    // Hover and keyboard focus draw the same ring; a press darkens the still.
    Rectangle {
        anchors.fill: frame
        radius: frame.radius
        color: root.pressed ? Theme.tint(Theme.ground, 0.4) : "transparent"
        border.width: root.lit ? 2 : 1
        border.color: root.lit ? Theme.gilt : Theme.rule

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }
    }

    ColumnLayout {
        id: labels

        anchors.top: frame.bottom
        anchors.topMargin: 10
        width: parent.width
        spacing: 2

        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            IconImage {
                visible: root.icon !== ""
                implicitSize: 16
                source: root.icon
            }

            BarText {
                Layout.fillWidth: true
                text: root.title
                color: root.lit ? Theme.gilt : Theme.text
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        BarText {
            visible: text !== ""
            Layout.fillWidth: true
            text: root.detail
            color: Theme.text2
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
