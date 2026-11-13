pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The case's and peripherals' RGB through the system's OpenRGB server (openrgb.service,
// hosts/common/desktop/rgb.nix), by the quickshell-rgb helper (scripts/rgb.py): the presets
// below on every device at once, or a profile saved in OpenRGB. Every helper run prints the
// state after it, so a click and a read are one process. The last choice is kept in the state
// dir and put back whenever the server has started again (a boot, or the VFIO VM giving the
// devices back), since the devices come up in their own lighting.
// A choice reads as current while every device still shows the mode and colours it left (the
// server doesn't say which profile or preset is on), so a change from OpenRGB itself clears it.
Singleton {
    id: root

    // `color`: one colour on every device (Static where it has it, else Direct). `command`: the
    // helper's own. Off uses a device's Off mode, else dark; Spectrum its slow colour cycle.
    readonly property var presets: [
        {
            id: "gilt",
            name: "Gilt",
            color: "#c9a24f"
        },
        {
            id: "warm",
            name: "Warm white",
            color: "#ffb46b"
        },
        {
            id: "white",
            name: "White",
            color: "#ffffff"
        },
        {
            id: "ice",
            name: "Ice blue",
            color: "#8fb0d3"
        },
        {
            id: "ember",
            name: "Ember",
            color: "#e0603a"
        },
        {
            id: "spectrum",
            name: "Spectrum",
            command: "spectrum"
        },
        {
            id: "off",
            name: "Off",
            command: "off"
        }
    ]

    // A reading has come back.
    property bool known: false
    // The server answered, and its run (openrgb.service's invocation id).
    property bool running: false
    property string server: ""
    // [{ name, mode, state }]: state is the mode and a digest of its colours.
    property var devices: []
    // The profiles' names.
    property var profiles: []
    // From the last change: devices it had no mode for (and the preset's name), and why it failed.
    property var skipped: []
    property string skippedFor: ""
    property string error: ""
    // The choice being applied: a preset id, or "profile:NAME".
    property string pending: ""
    // The state file has been read (or found missing).
    property bool stateRead: false
    // The device names restore() last saw, to wait out OpenRGB's detection.
    property string seenDevices: ""

    readonly property string fingerprint: devices.map(device => `${device.name}\t${device.state}`).join("\n")
    readonly property string current: state.choice !== "" && state.fingerprint === fingerprint ? state.choice : ""

    function refresh() {
        run("", ["quickshell-rgb", "status"]);
    }

    // A preset id, or "profile:NAME".
    function choose(choice: string) {
        if (choice.startsWith("profile:")) {
            run(choice, ["quickshell-rgb", "profile", choice.slice(8)]);
            return;
        }
        const preset = presets.find(entry => entry.id === choice);
        if (preset)
            run(choice, preset.color ? ["quickshell-rgb", "color", preset.color.slice(1)] : ["quickshell-rgb", preset.command]);
    }

    // One helper at a time; a change asked for while one runs replaces any other waiting, and a
    // read waits behind it rather than overtaking it.
    function run(choice: string, command: var) {
        if (helper.running) {
            if (choice !== "" || helper.queued === null)
                helper.queued = {
                    choice,
                    command
                };
            return;
        }
        pending = choice;
        helper.command = command;
        helper.running = true;
    }

    function finished(text: string) {
        let reading;
        try {
            reading = JSON.parse(text);
        } catch (e) {
            reading = {
                running,
                server,
                devices,
                profiles,
                skipped: [],
                error: "The OpenRGB helper gave no answer."
            };
        }
        known = true;
        running = reading.running;
        server = reading.server;
        devices = reading.devices;
        profiles = reading.profiles;
        if (pending !== "") {
            skipped = reading.skipped;
            skippedFor = presets.find(entry => entry.id === pending)?.name ?? "";
            error = reading.error;
            // Kept when it went on at least somewhere; a preset no device has changed nothing.
            if (reading.error === "" && reading.running && reading.skipped.length < reading.devices.length) {
                state.choice = pending;
                state.fingerprint = fingerprint;
                state.server = server;
            }
        } else if (reading.error !== "" || !reading.running) {
            // A read replaces a change's failure only with news: its own failure, or no server.
            error = reading.error;
        }
        pending = "";
    }

    // Once per server run, the last choice goes back on, when the state is read and the server
    // answers with its devices. Detection adds them one at a time with the server already up, so
    // two readings in a row must name the same devices first.
    function restore() {
        if (!stateRead || server === "" || state.server === server || helper.running)
            return;
        if (state.choice === "") {
            state.server = server;
            return;
        }
        const names = devices.map(device => device.name).join("\n");
        if (!running || devices.length === 0 || names !== seenDevices) {
            seenDevices = names;
            if (retries.count < 12)
                retries.start();
            return;
        }
        state.server = server;
        choose(state.choice);
    }

    Component.onCompleted: refresh()

    Process {
        id: helper

        property var queued: null

        stdout: StdioCollector {
            id: helperOut
            onStreamFinished: root.finished(helperOut.text)
        }
        // A queued run goes next; with none, a reading may be what a restore was waiting for.
        onExited: {
            const next = queued;
            queued = null;
            Qt.callLater(() => next === null ? root.restore() : root.run(next.choice, next.command));
        }
    }

    // The server may still be finding its devices when the bar starts at login (a minute at most).
    Timer {
        id: retries

        property int count: 0

        interval: 5000
        onTriggered: {
            count++;
            root.refresh();
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("lighting.json")
        printErrors: false
        // Writes one after another would otherwise reload an earlier one over the adapter.
        blockWrites: true
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.stateRead = true;
            root.restore();
        }
        // A first run has no file yet: nothing to restore.
        onLoadFailed: {
            root.stateRead = true;
            root.restore();
        }

        JsonAdapter {
            id: state

            property string choice: ""
            // The devices right after it went on (fingerprint).
            property string fingerprint: ""
            property string server: ""
        }
    }
}
