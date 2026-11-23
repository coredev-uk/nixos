import QtQuick
import QtMultimedia
import Quickshell.Wayland
import qs.common

// The wallpaper's aerial clip (QS_LOCK_VIDEO, from wallpaper-video in hypr/paper.nix; the greeter
// plays its copy), looped over the still, which shows until the first frame and wherever the clip
// can't play. Paused after 30 s without input and during unlock/login to save decoding.
// Loaded by URL from LockSurface so instances without Qt Multimedia never compile it.
Item {
    id: root

    property string path
    property bool running: true
    property bool hasFrame: false
    readonly property bool playing: running && !idle.isIdle

    opacity: hasFrame ? 1 : 0

    onPlayingChanged: playing ? player.play() : player.pause()
    Component.onCompleted: {
        if (playing)
            player.play();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 600
            easing.type: Theme.easing
        }
    }

    // Input only: music holding off hypridle mustn't keep the video running.
    IdleMonitor {
        id: idle

        timeout: 30
        respectInhibitors: false
    }

    MediaPlayer {
        id: player

        source: `file://${root.path}`
        loops: MediaPlayer.Infinite
        videoOutput: output
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Connections {
        target: output.videoSink
        enabled: !root.hasFrame

        function onVideoFrameChanged() {
            root.hasFrame = true;
        }
    }
}
