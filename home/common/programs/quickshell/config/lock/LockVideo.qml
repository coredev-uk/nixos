import QtQuick
import QtMultimedia
import Quickshell.Wayland

// The wallpaper's aerial clip, looped over the still it starts on (QS_LOCK_VIDEO, made by
// wallpaper-video in home/common/programs/hypr/paper.nix). It fades in on its first frame, so
// the still shows until then and wherever the clip can't play. Paused after half a minute
// without input, and for the unlock: nobody's watching then, and decoding two screens of video
// isn't free. Loaded by URL from LockSurface, so the greeter, which has no Qt Multimedia, never
// compiles it.
Item {
    id: root

    property string path
    // Off while unlocking.
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
            easing.type: Easing.OutCubic
        }
    }

    // Input alone: music holding off hypridle shouldn't keep the video running.
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
