import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common

// One screen of the lock. Idle: the wallpaper lightly blurred under a big clock. Active (any key or
// click): the blur deepens, the clock folds away and the password card pops up with its wings.
Rectangle {
    id: root

    required property LockContext context

    // Set by the quickshell-lock wrapper (home/common/programs/quickshell/default.nix).
    readonly property string wallpaperPath: Quickshell.env("QS_LOCK_WALLPAPER") ?? ""
    // Layout scale, 1 at 1080p.
    readonly property real s: Math.max(0.75, height / 1080)

    color: Theme.crust

    Image {
        id: wallpaper

        // Overscan: the blur pulls transparent pixels in from past the edges.
        anchors.fill: parent
        anchors.margins: -64
        source: root.wallpaperPath !== "" ? `file://${root.wallpaperPath}` : ""
        // Blurred anyway, so a quarter of the pixels is plenty.
        sourceSize.width: Math.round(root.width / 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: root.context.active ? 1 : 0.55
        saturation: root.context.active ? -0.15 : 0.1
        opacity: wallpaper.status === Image.Ready ? 1 : 0

        Behavior on blur {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on saturation {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }
    }

    // Flat scrim so text holds up on bright wallpapers; lighter while the card brings its own surface.
    Rectangle {
        anchors.fill: parent
        color: Theme.crust
        opacity: root.context.active ? 0.3 : 0.4

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }

    // Clicking anywhere brings up the card and gives the keyboard back to the password field.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.context.activate();
            panel.focusInput();
        }
    }

    Item {
        id: content

        anchors.fill: parent
        opacity: 0

        Component.onCompleted: opacity = 1

        Behavior on opacity {
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutCubic
            }
        }

        LockClock {
            anchors.fill: parent
            context: root.context
            s: root.s
        }

        LockPanel {
            id: panel

            anchors.fill: parent
            context: root.context
            s: root.s
        }

        LockPower {
            context: root.context
            s: root.s
        }
    }
}
