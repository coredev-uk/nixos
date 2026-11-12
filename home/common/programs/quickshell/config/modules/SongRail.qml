import QtQuick
import qs.common
import qs.widgets

// The song as a track along now playing's floor, drawn like the bar's day arc: the length in
// rule, what has played lit in text at 42%, and a gilt dot at now. Under the pointer the dot
// grows and a tooltip-style plate above the track names the time a press would go to; a press or
// a drag seeks there, once per pause in the drag.
Item {
    id: root

    required property var player
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property bool canSeek: (player?.canSeek ?? false) && length > 0
    readonly property bool near: area.containsMouse || area.pressed
    readonly property bool dragging: area.pressed
    readonly property real dragSeconds: area.fraction * length
    // Whether the card is on screen. Opening it places the dot; only playing moves it on.
    property bool active: false
    // The surface under the track, which rings the dot.
    property color ground: Theme.plate

    function clamp(v: real): real {
        return Math.max(0, Math.min(1, v));
    }

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // Read four times a second by the popup and glided through at an even pace in between.
    property real played: length > 0 ? clamp((player?.position ?? 0) / length) : 0
    property bool glide: false
    onActiveChanged: {
        glide = false;
        if (active)
            settle.restart();
    }
    Timer {
        id: settle
        interval: 300
        onTriggered: root.glide = root.active
    }
    Component.onCompleted: {
        if (active)
            settle.restart();
    }
    Behavior on played {
        enabled: root.glide && !area.pressed
        NumberAnimation {
            duration: 250
            easing.type: Easing.Linear
        }
    }
    readonly property real shown: area.pressed ? area.fraction : played

    implicitHeight: 16

    Timer {
        id: seek
        interval: 120
        onTriggered: {
            if (root.canSeek)
                root.player.position = root.dragSeconds;
        }
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 11

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 2
            color: Theme.rule
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(root.shown * parent.width)
            height: 2
            color: Theme.tint(Theme.text, 0.42)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(root.shown * parent.width - width / 2)
            width: root.near && root.canSeek ? 11 : 7
            height: width
            radius: width / 2
            color: Theme.gilt
            border.color: root.ground
            border.width: 1
            visible: root.length > 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }
    }

    // The time a press would go to (or, dragging, is going to), on a tooltip's plate.
    Rectangle {
        visible: root.near && root.canSeek
        x: Math.max(0, Math.min(root.width - width, (area.pressed ? root.shown : area.hoverFraction) * track.width - width / 2))
        y: -height - 4
        width: tip.implicitWidth + 12
        height: tip.implicitHeight + 6
        radius: Theme.radiusRow
        color: Theme.plate
        border.color: Theme.rule
        border.width: 1

        BarText {
            id: tip
            anchors.centerIn: parent
            text: root.clock((area.pressed ? root.shown : area.hoverFraction) * root.length)
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: area

        property real fraction: 0
        property real hoverFraction: 0

        function at(mx: real): real {
            return root.clamp(mx / track.width);
        }

        anchors.fill: parent
        anchors.topMargin: -4
        enabled: root.canSeek
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: e => {
            fraction = at(e.x);
            seek.restart();
        }
        onPositionChanged: e => {
            hoverFraction = at(e.x);
            if (pressed) {
                fraction = hoverFraction;
                seek.restart();
            }
        }
        onReleased: {
            seek.stop();
            if (root.canSeek)
                root.player.position = root.dragSeconds;
        }
    }
}
