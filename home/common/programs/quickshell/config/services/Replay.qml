pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Instant replay: gpu-screen-recorder keeps the last few minutes of the primary monitor and of what
// the default output plays in RAM, and a save writes them, or just their last stretch, to the
// recordings folder (the capture menu, modules/CaptureMenu.qml; Super+Shift+C for the last 30 s,
// Super+Ctrl+Shift+C for all of it; `quickshell ipc -c bar call replay save|clip SECONDS`).
// The buffer runs as the quickshell-replay user unit (default.nix), which systemd supervises and
// which outlives the bar, so a restart on switch doesn't empty it. Whether it is armed is kept in
// the state dir like Do Not Disturb, and the bar starts the unit again at login. Buffering shares
// nothing, so it isn't on air (Privacy): the capture glyph is gilt while it is armed. The clip is
// named and announced by scripts/record.sh.
Singleton {
    id: root

    readonly property string unit: "quickshell-replay.service"
    // Both set by default.nix, which owns them for the unit as well.
    readonly property int seconds: Number(Quickshell.env("QS_REPLAY_SECONDS"))
    readonly property string monitor: Quickshell.env("QS_REPLAY_MONITOR")
    readonly property bool armed: state.armed
    // The unit is running: false while it is starting or restarting after a failure.
    property bool active: false

    // "5 min", "1 h 30 min".
    readonly property string span: {
        const minutes = Math.round(seconds / 60);
        return minutes < 60 ? `${minutes} min` : minutes % 60 ? `${Math.floor(minutes / 60)} h ${minutes % 60} min` : `${minutes / 60} h`;
    }

    // Reads whether the unit is running; also what brings the service up with the bar.
    function refresh() {
        status.running = true;
    }

    function toggle() {
        if (armed)
            disarm();
        else
            arm();
    }

    function arm() {
        state.armed = true;
        start();
    }

    function disarm() {
        state.armed = false;
        active = false;
        control.run(["sh", "-c", `systemctl --user stop ${unit}; systemctl --user reset-failed ${unit}`]);
        poll.stop();
    }

    // The recorder writes the whole buffer on SIGUSR1, and only its end on SIGRTMIN+1..6 (these
    // lengths, gpu-screen-recorder(1)); record.sh takes it from there.
    readonly property var clipSignals: ({
            "10": "SIGRTMIN+1",
            "30": "SIGRTMIN+2",
            "60": "SIGRTMIN+3",
            "300": "SIGRTMIN+4",
            "600": "SIGRTMIN+5",
            "1800": "SIGRTMIN+6"
        })

    // All of the buffer, or (with `last`, one of clipSignals' lengths shorter than it) its end.
    function save(last: int) {
        if (!armed || !active) {
            fail("Instant replay isn't running. Turn it on from the capture menu first.");
            return;
        }
        const signal = last > 0 && last < seconds ? clipSignals[String(last)] : "SIGUSR1";
        if (!signal) {
            fail(`Can't save the last ${last} seconds: gpu-screen-recorder saves 10 s, 30 s, 1, 5, 10 or 30 min.`);
            return;
        }
        saver.run(["systemctl", "--user", "kill", "--kill-whom=main", `--signal=${signal}`, unit]);
    }

    function start() {
        control.run(["systemctl", "--user", "start", unit]);
        poll.restart();
    }

    function fail(reason: string) {
        Quickshell.execDetached(["quickshell-record", "--failed", "Instant replay", reason]);
    }

    // The unit gave up after repeated failures (StartLimitBurst): say why and switch off, so a
    // login doesn't try again silently.
    function gaveUp() {
        why.run(["sh", "-c", `journalctl --user -u ${unit} -n 40 -o cat | grep -i error | tail -n 1`]);
    }

    // Runs whichever command it is given, one at a time: one given while another runs waits for
    // it (like Brightness's writer) instead of being dropped. Once each has finished, the unit's
    // state is read.
    component Command: Process {
        property var queued: null

        function run(args: var) {
            if (running) {
                queued = args;
                return;
            }
            command = args;
            running = true;
        }

        onExited: {
            if (queued === null)
                return;
            const next = queued;
            queued = null;
            Qt.callLater(() => run(next));
        }
    }

    Command {
        id: control
        onExited: status.running = true
    }

    Command {
        id: saver
    }

    Command {
        id: why
        stdout: StdioCollector {
            id: reasonOut
            onStreamFinished: {
                const line = reasonOut.text.trim().replace(/^gsr (error|info): /, "");
                root.fail(`The buffer stopped and is turned off${line === "" ? "." : `: ${line}`}`);
                root.disarm();
            }
        }
    }

    // `systemctl is-active` prints the state: active, activating (also between automatic restarts),
    // failed once it gave up, inactive.
    Process {
        id: status
        command: ["systemctl", "--user", "is-active", root.unit]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: {
                const unitState = statusOut.text.trim();
                root.active = unitState === "active";
                if (unitState === "failed")
                    root.gaveUp();
            }
        }
    }

    // Notices a unit that failed for good; no more than a process every few seconds, only while armed.
    Timer {
        id: poll
        interval: 5000
        repeat: true
        onTriggered: status.running = true
    }

    FileView {
        path: Quickshell.statePath("replay.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        // The unit doesn't survive a logout (it is part of the graphical session): start it again.
        onLoaded: {
            if (state.armed)
                root.start();
        }

        JsonAdapter {
            id: state

            property bool armed: false
        }
    }

    IpcHandler {
        target: "replay"

        function toggle(): void {
            root.toggle();
        }
        function save(): void {
            root.save(0);
        }
        // The last SECONDS of it: 10, 30, 60, 300, 600 or 1800.
        function clip(seconds: int): void {
            root.save(seconds);
        }
    }
}
