import QtQuick
import Quickshell

// State shared by every screen's surface, whatever checks the password: one password buffer
// and the idle -> active -> finishing flow all screens follow together. LockContext (PAM) and
// GreeterContext (greetd) build on it: they run the check when `submitted` fires and report
// back through succeed() or fail().
Scope {
    id: root

    // tryUnlock() accepted the input; check currentText now.
    signal submitted
    // The outro has played; unlock or start the session now.
    signal finished

    property string currentText: ""
    // Whose password this is; the greeter sets it, the lock screen is always its own user.
    property string user: Quickshell.env("USER") ?? ""
    // False before login (the greeter): no calendar, music or other user-session widgets.
    property bool hasUserSession: true
    // Idle shows the clock and the date; any key or click brings up the password.
    property bool active: false
    // Authenticated; surfaces play their outro before `finished` fires.
    property bool unlocking: false
    // A check is running; set by the backend.
    property bool checking: false
    // Shown under the password; cleared as soon as the user types again.
    property string statusText: ""
    property bool statusIsError: false
    // Guessed from typed letters vs Shift (Qt exposes no Caps Lock state).
    property bool capsLock: false
    // Bumped on every rejected attempt so each surface can replay its shake.
    property int failures: 0

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

    // Escape: clear the field first, then go back to the clock.
    function cancel() {
        if (checking || unlocking)
            return;
        if (currentText !== "")
            currentText = "";
        else
            active = false;
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

    // A rejected or failed attempt: clear the field and say why.
    function fail(message: string) {
        currentText = "";
        statusText = message;
        statusIsError = true;
        failures++;
    }

    // Informational text from the backend that needs no answer.
    function notice(message: string, isError: bool) {
        statusText = message;
        statusIsError = isError;
    }

    // Back to the clock after a while with nothing typed.
    Timer {
        interval: 15000
        running: root.active && root.currentText === "" && !root.checking && !root.unlocking
        onTriggered: root.active = false
    }

    Timer {
        id: outroTimer

        // Matches the surfaces' fold-away animation.
        interval: 380
        onTriggered: root.finished()
    }
}
