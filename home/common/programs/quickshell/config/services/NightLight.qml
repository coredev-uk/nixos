pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light follows wlsunset's sunset schedule (home/common/programs/hypr/sunset.nix). A colour
// temperature picked in the panel overrides it for the rest of the session: wlsunset stops and a
// transient hyprsunset unit holds the temperature, adjusted live over its IPC while dragging (a
// wlsunset restart per change would flash the screen back to daylight in between). Nothing is
// saved, so the next login is back on the schedule; following the schedule again ends the override.
Singleton {
    id: root

    readonly property string overrideUnit: "night-light-override"
    // Kelvin range of the panel slider; 6500K is neutral.
    readonly property int warmest: 2000
    readonly property int neutral: 6500

    // wlsunset is running its schedule.
    property bool scheduled: false
    // The session's temperature, 0 when not overriding.
    property int custom: 0
    // The schedule's night temperature, read from wlsunset's command line.
    property int nightTemperature: 4000
    readonly property bool active: scheduled || custom > 0

    function refresh() {
        query.running = true;
    }

    // Off, or back from an override, goes to the schedule; the schedule turns off.
    function toggle() {
        if (custom > 0 || !scheduled)
            followSchedule();
        else
            run(["systemctl", "--user", "stop", "wlsunset.service"]);
    }

    function followSchedule() {
        custom = 0;
        run(["sh", "-c", `systemctl --user stop ${overrideUnit}.service; systemctl --user start wlsunset.service`]);
    }

    function setTemperature(kelvin: int) {
        const value = Math.max(warmest, Math.min(neutral, Math.round(kelvin / 50) * 50));
        const starting = custom === 0;
        custom = value;
        if (starting) {
            scheduled = false;
            run(["sh", "-c", `systemctl --user stop wlsunset.service; systemctl --user reset-failed ${overrideUnit}.service 2>/dev/null; systemd-run --user --quiet --collect --unit=${overrideUnit} hyprsunset --temperature ${value}`]);
        } else {
            apply.restart();
        }
    }

    function run(command: var) {
        control.command = command;
        control.running = true;
    }

    Component.onCompleted: refresh()

    // Coalesces a drag into a few IPC calls.
    Timer {
        id: apply
        interval: 60
        onTriggered: {
            if (!temperatureIpc.running) {
                temperatureIpc.command = ["hyprctl", "hyprsunset", "temperature", String(root.custom)];
                temperatureIpc.running = true;
            } else {
                restart();
            }
        }
    }

    // hyprsunset takes a moment to open its socket after the unit starts; a drag that early is
    // retried for up to a couple of seconds.
    Process {
        id: temperatureIpc

        property int retries: 0

        onExited: code => {
            if (code === 0 || root.custom === 0 || retries >= 20) {
                retries = 0;
                return;
            }
            retries++;
            apply.restart();
        }
    }

    // wlsunset's state and night temperature, and the override's temperature if one is running
    // (it outlives a bar restart).
    Process {
        id: query
        command: ["sh", "-c", `systemctl --user is-active --quiet wlsunset.service && echo scheduled; systemctl --user show -p ExecStart --value wlsunset.service; systemctl --user is-active --quiet ${root.overrideUnit}.service && echo override && hyprctl hyprsunset temperature`]
        stdout: StdioCollector {
            id: queryOut
            onStreamFinished: {
                const text = queryOut.text;
                root.scheduled = /^scheduled$/m.test(text);
                const night = /\s-t\s*(\d+)/.exec(text);
                if (night)
                    root.nightTemperature = Number(night[1]);
                if (!/^override$/m.test(text)) {
                    root.custom = 0;
                    return;
                }
                // `hyprctl hyprsunset temperature` alone prints the current value; right after the
                // unit starts its socket isn't up yet, and the value just set stands.
                const current = /^(\d{4,5})\s*$/m.exec(text);
                if (current)
                    root.custom = Number(current[1]);
            }
        }
    }

    Process {
        id: control
        onExited: root.refresh()
    }
}
