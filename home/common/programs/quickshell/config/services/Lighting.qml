pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The case's and peripherals' RGB through the system's OpenRGB server (openrgb.service,
// hosts/common/desktop/rgb.nix), by the quickshell-rgb helper (scripts/rgb.py). The looks are
// the helper's: plain colours, effects drawn LED by LED, and off, on every device at once.
// Choosing one records it for the engine (quickshell-rgb.service), which draws it and puts it
// back whenever the server starts again; every helper run prints the state after it, so a click
// and a read are one process.
Singleton {
    id: root

    // A reading has come back.
    property bool known: false
    // The server answered, and the engine is running.
    property bool running: false
    property bool engine: false
    // [{ name, leds }]
    property var devices: []
    // [{ id, name, kind: "color" | "effect" | "off", colors: ["#rrggbb"] }]
    property var looks: []
    readonly property var colours: looks.filter(look => look.kind !== "effect")
    readonly property var effects: looks.filter(look => look.kind === "effect")
    // The chosen look's id ("" for none).
    property string current: ""
    property string error: ""
    // The look being chosen.
    property string pending: ""

    function refresh() {
        run("", ["quickshell-rgb", "status"]);
    }

    function choose(id: string) {
        run(id, ["quickshell-rgb", "set", id]);
    }

    // One helper at a time; a choice asked for while one runs replaces any other waiting, and a
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
            error = "The OpenRGB helper gave no answer.";
            pending = "";
            known = true;
            return;
        }
        known = true;
        running = reading.running;
        engine = reading.engine;
        devices = reading.devices;
        looks = reading.looks;
        current = reading.look;
        error = reading.error;
        pending = "";
    }

    Component.onCompleted: refresh()

    Process {
        id: helper

        property var queued: null

        stdout: StdioCollector {
            id: helperOut
            onStreamFinished: root.finished(helperOut.text)
        }
        onExited: {
            const next = queued;
            queued = null;
            if (next !== null)
                Qt.callLater(() => root.run(next.choice, next.command));
        }
    }
}
