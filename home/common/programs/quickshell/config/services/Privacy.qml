pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

    // Re-runs xdph's share picker and points every running screen share at the choice
    // (SwitchSource, patched into xdph in overlays/default.nix). The shares hold their last frame
    // while the picker is up; cancelling it leaves them as they were.
    function switchScreen() {
        if (screen.length > 0 && !switcher.running)
            switcher.running = true;
    }

    Captures {
        id: captures
    }

    Process {
        id: switcher

        // The call returns once the picker closes, so no D-Bus timeout.
        command: ["busctl", "--user", "--timeout=infinity", "call", "org.freedesktop.impl.portal.desktop.hyprland", "/org/freedesktop/portal/desktop", "uk.coredev.xdph.ScreenCast", "SwitchSource"]
        stderr: StdioCollector {
            onStreamFinished: {
                if (text !== "")
                    console.warn(`Privacy: switching the shared screen failed: ${text}`);
            }
        }
    }
}
