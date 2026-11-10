import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland

// The lock screen's password check: PAM, against the quickshell-lock service. Idle locks
// (quickshell-lock --grace) also open a grace period, in which any input unlocks without it.
AuthContext {
    id: root

    // The deadline is on the wall clock, which keeps running through a suspend, so a sleep that
    // starts inside the window can't carry it to the wake.
    readonly property real graceSeconds: parseFloat(Quickshell.env("QS_LOCK_GRACE")) || 0

    checking: pam.active
    graceUntil: Date.now() + graceSeconds * 1000
    graceOpen: graceSeconds > 0

    onSubmitted: pam.start()

    PamContext {
        id: pam

        // /etc/pam.d/quickshell-lock, from security.pam.services in hosts/common/desktop/hyprland.nix.
        config: "quickshell-lock"

        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
            else
                root.notice(message, messageIsError);
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.succeed();
            else
                root.fail(result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password");
        }

        onError: error => root.fail(`Authentication unavailable (${PamError.toString(error)})`)
    }

    // Closes on the wall clock, like the check below: a Timer doesn't count a suspend, so it
    // would leave the indicator up after a wake.
    Timer {
        interval: 250
        repeat: true
        running: root.graceOpen
        onTriggered: {
            if (Date.now() >= root.graceUntil)
                root.graceOpen = false;
        }
    }

    // Reports idle a tenth of a second after the last input and comes back on the next, from
    // the compositor, so it hears the keyboard and pointer on every screen, password field or
    // not. Inhibitors ignored: playing music holds one.
    IdleMonitor {
        enabled: root.graceOpen
        timeout: 0.1
        respectInhibitors: false

        // Turning it off also reads as "not idle", so check the window is still open.
        onIsIdleChanged: {
            if (!isIdle && root.graceOpen && Date.now() < root.graceUntil && !root.unlocking)
                root.succeed();
        }
    }
}
