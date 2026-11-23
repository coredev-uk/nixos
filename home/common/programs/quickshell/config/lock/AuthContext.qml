import QtQuick
import Quickshell

// State shared by every screen's surface: one password buffer and the idle -> active -> finishing
// flow. LockContext (PAM) and GreeterContext (greetd) run the check on `submitted` and report via
// succeed() or fail().
Scope {
    id: root

    signal submitted
    signal finished

    property string currentText: ""
    // The greeter sets it; the lock is always its own user.
    property string user: Quickshell.env("USER") ?? ""
    // False on the greeter: no calendar, music or other user-session widgets.
    property bool hasUserSession: true
    property bool active: false
    property bool unlocking: false
    property bool checking: false
    property string statusText: ""
    property bool statusIsError: false
    // Guessed from typed letters vs Shift (Qt exposes no Caps Lock state).
    property bool capsLock: false
    property int failures: 0
    // Lock idle grace (LockContext): until graceUntil (ms since epoch) any input unlocks. Never open on the greeter.
    property bool graceOpen: false
    property real graceUntil: 0

    onCurrentTextChanged: {
        if (currentText !== "") {
            statusText = "";
            activate();
        }
    }

    function activate() {
        if (!unlocking)
            active = true;
    }

    function cancel() {
        if (checking || unlocking)
            return;
        if (currentText !== "")
            currentText = "";
        else
            idle();
    }

    // Drops any old message so it doesn't greet the next wake.
    function idle() {
        active = false;
        statusText = "";
        statusIsError = false;
    }

    function tryUnlock() {
        if (currentText === "" || checking || unlocking)
            return;
        statusText = "";
        submitted();
    }

    function succeed() {
        unlocking = true;
        outroTimer.start();
    }

    function fail(message: string) {
        currentText = "";
        statusText = message;
        statusIsError = true;
        failures++;
    }

    function notice(message: string, isError: bool) {
        statusText = message;
        statusIsError = isError;
    }

    Timer {
        interval: 15000
        running: root.active && root.currentText === "" && !root.checking && !root.unlocking
        onTriggered: root.idle()
    }

    Timer {
        id: outroTimer

        // Matches the surfaces' fold-away animation.
        interval: 380
        onTriggered: root.finished()
    }
}
