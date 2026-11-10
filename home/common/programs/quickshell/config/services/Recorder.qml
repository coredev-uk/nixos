pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen recording: gpu-screen-recorder (hardware encoding) capturing the focused monitor and what
// the default output plays into the recordings folder (xdg.userDirs, set as QS_RECORDINGS_DIR by
// default.nix), started and stopped by `quickshell ipc -c bar call recorder toggle` (Super+Shift+R)
// or the capture menu (modules/CaptureMenu.qml), whose bar glyph shows the time. A recording
// counts as on air (Privacy.onAir) from the moment it starts until the file is finished. The
// recorder runs through the quickshell-record helper (scripts/record.sh), which also raises the
// notifications: the file when it's saved, the reason when it fails.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("QS_RECORDINGS_DIR")

    // True until the recorder has exited, SIGINT's finishing of the file included.
    readonly property bool recording: process.running
    // Stop sent; the file is being finished.
    property bool stopping: false
    // What the running (or last) recording captures and writes.
    property string monitor: ""
    property string file: ""
    // Whole seconds since it started, and as "mm:ss" ("h:mm:ss" past an hour).
    property int elapsed: 0
    readonly property string elapsedText: {
        const pad = n => String(n).padStart(2, "0");
        const rest = `${pad(Math.floor(elapsed / 60) % 60)}:${pad(elapsed % 60)}`;
        return elapsed >= 3600 ? `${Math.floor(elapsed / 3600)}:${rest}` : rest;
    }

    // Recorder messages that end up in a failure notification: its last "gsr error:" line, else
    // its last line.
    property string errorLine: ""
    property string lastLine: ""
    property double startedAt: 0

    function toggle() {
        if (recording)
            stop();
        else
            start();
    }

    function start() {
        if (recording)
            return;
        const name = Hyprland.focusedMonitor?.name ?? "";
        if (name === "") {
            fail("There is no focused screen to record.");
            return;
        }
        monitor = name;
        file = `${dir}/recording-${Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")}.mp4`;
        errorLine = "";
        lastLine = "";
        stopping = false;
        elapsed = 0;
        process.command = ["quickshell-record", "--start", monitor, file];
        process.running = true;
    }

    // SIGINT makes the recorder finish the file and exit.
    function stop() {
        if (!recording || stopping)
            return;
        stopping = true;
        process.signal(2);
        killTimer.restart();
    }

    function fail(reason: string) {
        Quickshell.execDetached(["quickshell-record", "--failed", "Recording failed", reason]);
    }

    Process {
        id: process

        stderr: SplitParser {
            onRead: line => {
                if (line.trim() === "")
                    return;
                root.lastLine = line;
                if (/error/i.test(line))
                    root.errorLine = line;
            }
        }
        onStarted: {
            root.startedAt = Date.now();
            tick.start();
        }
        onExited: (code, status) => {
            tick.stop();
            killTimer.stop();
            root.stopping = false;
            // Exit status 0 is a normal exit; a signal or crash is 1, with no meaningful code.
            if (status === 0 && code === 0) {
                Quickshell.execDetached(["quickshell-record", "--saved", "Recording saved", root.file]);
                return;
            }
            const message = (root.errorLine || root.lastLine).replace(/^gsr (error|info): /, "");
            root.fail(message !== "" ? message : `The recorder stopped unexpectedly (status ${code}).`);
        }
    }

    // Elapsed is sampled twice a second so a second never shows late; it only changes once.
    Timer {
        id: tick
        interval: 500
        repeat: true
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    // A recorder that ignores SIGINT must not leave the indicator up.
    Timer {
        id: killTimer
        interval: 10000
        onTriggered: process.signal(9)
    }

    // The lock is a separate instance with no way to see a recording (KMS capture leaves nothing
    // in PipeWire), so it reads this (services/RecordingStatus.qml). Written at startup too, which
    // clears what a bar that died mid-recording left; the recorder dies with the bar.
    Component.onCompleted: publish()
    onRecordingChanged: publish()

    function publish() {
        status.setText(JSON.stringify({
            recording: recording
        }));
    }

    FileView {
        id: status

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-recording.json`
        blockLoading: false
        preload: false
        printErrors: false
    }

    IpcHandler {
        target: "recorder"

        function toggle(): void {
            root.toggle();
        }
        function start(): void {
            root.start();
        }
        function stop(): void {
            root.stop();
        }
    }
}
