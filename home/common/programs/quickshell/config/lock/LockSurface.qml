import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common

// One screen of the lock or greeter. The wallpaper is left sharp (its aerial clip playing over it
// on the lock screen, where there is one), with the time set large in its bottom-left corner and
// the date under it; today's events and what's playing sit bottom-right. Any key or click softens
// the picture and turns the date line into the password field, with the power buttons in place
// of what's playing. Unlocking sinks everything and sharpens the picture again.
Rectangle {
    id: root

    required property AuthContext context

    // Set by the quickshell-lock and quickshell-greeter wrappers.
    readonly property string wallpaperPath: Quickshell.env("QS_LOCK_WALLPAPER") ?? ""
    // The lock screen's only; the greeter has none.
    readonly property string videoPath: Quickshell.env("QS_LOCK_VIDEO") ?? ""
    // Layout scale, 1 at 1080p.
    readonly property real s: Math.max(0.75, height / 1080)
    // The outer margin, and the line under the time that holds the date or the password.
    readonly property real margin: Math.round(80 * s)
    readonly property real lineHeight: Math.round(56 * s)
    readonly property bool engaged: context.active && !context.unlocking
    // Drives the entrance (on the first frame) and the outro (on unlocking).
    property bool ready: false
    readonly property bool shown: ready && !context.unlocking

    color: Theme.ground

    Component.onCompleted: ready = true

    // The still and the clip over it, drawn under the blur that covers them: a video only
    // paints while it's visible, so this can't be a hidden effect source. Overscan: the blur
    // pulls transparent pixels in from past the edges.
    Item {
        id: backdrop

        anchors.fill: parent
        anchors.margins: -64

        Image {
            id: wallpaper

            anchors.fill: parent
            source: root.wallpaperPath !== "" ? `file://${root.wallpaperPath}` : ""
            // Shown sharp at rest, so at full size.
            sourceSize.width: root.width + 128
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Loader {
            anchors.fill: parent
            // By URL, so the greeter (no Qt Multimedia) never compiles it. Asynchronous, so the
            // lock's first frame (with the still) doesn't wait for Qt Multimedia and FFmpeg.
            asynchronous: true
            Component.onCompleted: {
                if (root.videoPath !== "")
                    setSource(Qt.resolvedUrl("LockVideo.qml"), {
                        path: root.videoPath
                    });
            }
            onLoaded: item.running = Qt.binding(() => !root.context.unlocking)
        }
    }

    // Under the blur until the still has loaded.
    Rectangle {
        anchors.fill: parent
        color: Theme.ground
    }

    MultiEffect {
        anchors.fill: backdrop
        source: backdrop
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: root.engaged ? 0.7 : 0
        saturation: root.engaged ? -0.2 : 0
        opacity: wallpaper.status === Image.Ready ? 1 : 0

        Behavior on blur {
            NumberAnimation {
                duration: 600
                easing.type: Theme.easing
            }
        }

        Behavior on saturation {
            NumberAnimation {
                duration: 600
                easing.type: Theme.easing
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Theme.easing
            }
        }
    }

    // Flat scrim so the text holds up on bright wallpapers; deeper with the password up.
    Rectangle {
        anchors.fill: parent
        color: Theme.ground
        opacity: root.engaged ? 0.42 : 0.18

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Theme.easing
            }
        }
    }

    // Clicking anywhere brings up the password and gives the keyboard back to it.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.context.activate();
            prompt.focusInput();
        }
    }

    Reveal {
        anchors.fill: parent
        shown: root.shown
        rise: 28 * root.s

        LockClock {
            anchors.fill: parent
            context: root.context
            s: root.s
            margin: root.margin
            lineHeight: root.lineHeight
        }
    }

    Reveal {
        anchors.fill: parent
        shown: root.shown
        rise: 28 * root.s
        delay: 90

        LockPrompt {
            id: prompt

            x: root.margin
            y: parent.height - root.margin - root.lineHeight
            width: parent.width / 2 - root.margin
            height: root.lineHeight
            context: root.context
            s: root.s
        }
    }

    Reveal {
        anchors.fill: parent
        shown: root.shown
        rise: 28 * root.s
        delay: 180

        // Today's events and the music come from the user session, so the greeter never loads them.
        Loader {
            anchors.fill: parent
            active: root.context.hasUserSession

            sourceComponent: LockToday {
                context: root.context
                s: root.s
                margin: root.margin
                lineHeight: root.lineHeight
            }
        }

        LockPower {
            anchors.right: parent.right
            anchors.rightMargin: root.margin
            y: parent.height - root.margin - (root.lineHeight + height) / 2
            s: root.s
            opacity: root.engaged ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                    easing.type: Theme.easing
                }
            }
        }
    }
}
