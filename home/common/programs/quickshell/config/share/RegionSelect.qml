import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.widgets

// Region sharing: the screen stays live under a dim, and a drag cuts the region out of it.
// Letting go shares it; Escape or a right click goes back to the picker. Coordinates are the
// output's own, in logical pixels, as xdph takes them.
PanelWindow {
    id: root

    required property var modelData

    // The region as "x,y,w,h" on this screen.
    signal chosen(string output, string region)
    signal back

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-share-region"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    property point from: Qt.point(0, 0)
    property point to: Qt.point(0, 0)
    property bool dragging: false
    readonly property rect area: Qt.rect(Math.min(from.x, to.x), Math.min(from.y, to.y), Math.abs(to.x - from.x), Math.abs(to.y - from.y))
    readonly property bool hasArea: area.width >= 1 && area.height >= 1
    readonly property color dim: Theme.tint(Theme.ground, 0.6)

    onVisibleChanged: {
        dragging = false;
        from = to = Qt.point(0, 0);
        if (visible)
            keys.forceActiveFocus();
    }

    // The dim, in four pieces around the region (all of it before a drag).
    Rectangle {
        width: parent.width
        height: root.hasArea ? root.area.y : parent.height
        color: root.dim
    }
    Rectangle {
        visible: root.hasArea
        y: root.area.y + root.area.height
        width: parent.width
        height: parent.height - y
        color: root.dim
    }
    Rectangle {
        visible: root.hasArea
        y: root.area.y
        width: root.area.x
        height: root.area.height
        color: root.dim
    }
    Rectangle {
        visible: root.hasArea
        x: root.area.x + root.area.width
        y: root.area.y
        width: parent.width - x
        height: root.area.height
        color: root.dim
    }

    Rectangle {
        visible: root.hasArea
        x: root.area.x - 1
        y: root.area.y - 1
        width: root.area.width + 2
        height: root.area.height + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.gilt
    }

    // The size, under the region's corner (above it near the bottom edge).
    Rectangle {
        id: size

        visible: root.hasArea
        x: Math.min(root.area.x, parent.width - width - 8)
        y: root.area.y + root.area.height + 8 + height > parent.height ? root.area.y - height - 8 : root.area.y + root.area.height + 8
        width: sizeText.implicitWidth + 16
        height: 24
        radius: Theme.radiusRow
        color: Theme.plate
        border.width: 1
        border.color: Theme.rule

        BarText {
            id: sizeText

            anchors.centerIn: parent
            text: `${Math.round(root.area.width)} × ${Math.round(root.area.height)}`
            font.pixelSize: 12
        }
    }

    // What to do, until the drag starts.
    Rectangle {
        visible: !root.dragging && !root.hasArea
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.12)
        width: hint.implicitWidth + 28
        height: 36
        radius: Theme.radiusPlate
        color: Theme.plate
        border.width: 1
        border.color: Theme.rule

        BarText {
            id: hint

            anchors.centerIn: parent
            text: "Drag to select a region · Esc to go back"
            font.pixelSize: 13
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: e => {
            if (e.button === Qt.RightButton) {
                root.back();
                return;
            }
            root.from = root.to = Qt.point(e.x, e.y);
            root.dragging = true;
        }
        onPositionChanged: e => {
            if (root.dragging)
                root.to = Qt.point(Math.max(0, Math.min(e.x, width)), Math.max(0, Math.min(e.y, height)));
        }
        onReleased: e => {
            if (!root.dragging)
                return;
            root.dragging = false;
            const a = root.area;
            // A click without a drag selects nothing.
            if (a.width < 4 || a.height < 4) {
                root.from = root.to = Qt.point(0, 0);
                return;
            }
            root.chosen(root.modelData.name, `${Math.round(a.x)},${Math.round(a.y)},${Math.round(a.width)},${Math.round(a.height)}`);
        }
    }

    Item {
        id: keys

        focus: true
        Keys.onEscapePressed: root.back()
    }
}
