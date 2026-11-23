pragma Singleton

import QtQuick
import Quickshell

// Apps currently capturing the microphone, camera, screen or system audio (Captures.qml), plus where
// audio is cast: the AirPlay speakers playing this computer's output. Each list holds { name, icon }.
// The shell's own screen recording (Recorder.qml) isn't listed (the capture glyph shows it) but counts
// as on air. Its instant replay buffer (Replay.qml) shares nothing until a clip is saved, so it isn't
// on air; the capture glyph is only gilt (on) while it runs.
Singleton {
    id: root

    readonly property var microphone: captures.microphone
    readonly property var camera: captures.camera
    readonly property var screen: captures.screen
    readonly property var systemAudio: captures.systemAudio
    // Screen casts already show up above: GNOME Network Displays records the screen and its own
    // sink like any other app.
    readonly property var cast: AirPlay.casting ? AirPlay.chosen.filter(speaker => !speaker.failed).map(speaker => ({
                name: speaker.name,
                icon: ""
            })) : []
    readonly property bool active: microphone.length + camera.length + screen.length + systemAudio.length + cast.length > 0
    // The screen is being shared or recorded: Pass quick access and the popups keep personal
    // detail off it.
    readonly property bool onAir: captures.onAir || recording
    // The shell's own screen recording: on air though no app is listed as sharing.
    readonly property bool recording: Recorder.recording

    Captures {
        id: captures
    }
}
