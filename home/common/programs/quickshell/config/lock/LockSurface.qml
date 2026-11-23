import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common

// One screen of the lock or greeter: sharp wallpaper (aerial clip over it on the lock), time and
// date bottom-left, events and music bottom-right. Any key or click softens the picture and turns
// the date line into the password field, with the power buttons replacing the music.
Rectangle {
    id: root

    required property AuthContext context

    // Set by the lock and greeter wrappers.
    readonly property string wallpaperPath: Quickshell.env("QS_LOCK_WALLPAPER") ?? ""
    // Set by the lock wrapper always, by the greeter's only when /var/lib/greeter-wallpaper has a clip.
    readonly property string videoPath: Quickshell.env("QS_LOCK_VIDEO") ?? ""
    readonly property real s: Math.max(0.75, height / 1080)
    // The outer margin, and the line under the time that holds the date or the password.
    readonly property real margin: Math.round(80 * s)
    readonly property real lineHeight: Math.round(56 * s)
    readonly property bool engaged: context.active && !context.unlocking
    property bool ready: false
    readonly property bool shown: ready && !context.unlocking

    color: Theme.ground

    Component.onCompleted: ready = true

    // Still and clip are drawn under the blur: a video only paints while visible, so it can't be a
    // hidden effect source. Overscan because the blur pulls in transparent pixels from past the edges.
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
            // Loaded by URL so an instance without Qt Multimedia (greeter, no clip) never compiles it;
            // asynchronous so the first frame doesn't wait for Qt Multimedia and FFmpeg.
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

    // Flat scrim so text holds on bright wallpapers; deeper with the password up.
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

        // The greeter never loads these: no user session.
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

    Reveal {
        anchors.fill: parent
        shown: root.shown && root.context.graceOpen
        rise: 28 * root.s
        delay: 270

        LockGrace {
            anchors.fill: parent
            context: root.context
            s: root.s
            margin: root.margin
        }
    }
}
