import QtQuick

// Single-line text that, when it doesn't fit its width, scrolls to the end and back,
// pausing at each end. Fits-in-place text stays still.
Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    // Scroll speed in pixels per second.
    property real speed: 40

    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    function restart() {
        scroll.stop();
        label.x = 0;
        if (overflow > 0 && visible)
            scroll.start();
    }

    onTextChanged: restart()
    onOverflowChanged: restart()
    onVisibleChanged: restart()
    Component.onCompleted: restart()

    BarText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
    }

    SequentialAnimation {
        id: scroll
        loops: Animation.Infinite

        PauseAnimation {
            duration: 2000
        }
        NumberAnimation {
            target: label
            property: "x"
            to: -root.overflow
            duration: root.overflow / root.speed * 1000
            easing.type: Easing.InOutSine
        }
        PauseAnimation {
            duration: 2000
        }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: root.overflow / root.speed * 1000
            easing.type: Easing.InOutSine
        }
    }
}
