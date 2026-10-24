import QtQuick
import Quickshell
import Quickshell.Services.Pam

// State shared by every screen's lock surface: one password buffer, one PAM conversation and the
// idle -> active -> unlocking flow all screens follow together.
Scope {
    id: root

    // The outro has played; release the session lock now.
    signal unlocked

    property string currentText: ""
    // Idle shows only the clock; any key or click brings up the password card.
    property bool active: false
    // Authenticated; surfaces play their outro before `unlocked` fires.
    property bool unlocking: false
    readonly property bool checking: pam.active
    // Shown under the user name; cleared as soon as the user types again.
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
        if (pam.active || unlocking)
            return;
        if (currentText !== "")
            currentText = "";
        else
            active = false;
    }

    function tryUnlock() {
        if (currentText === "" || pam.active || unlocking)
            return;
        statusText = "";
        pam.start();
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
        onTriggered: root.unlocked()
    }

    PamContext {
        id: pam

        // /etc/pam.d/quickshell-lock, from security.pam.services in hosts/common/desktop/hyprland.nix.
        config: "quickshell-lock"

        onPamMessage: {
            if (responseRequired) {
                respond(root.currentText);
            } else {
                root.statusText = message;
                root.statusIsError = messageIsError;
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocking = true;
                outroTimer.start();
                return;
            }
            root.currentText = "";
            root.statusText = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";
            root.statusIsError = true;
            root.failures++;
        }

        onError: error => {
            root.statusText = `Authentication unavailable (${PamError.toString(error)})`;
            root.statusIsError = true;
            root.failures++;
        }
    }
}
