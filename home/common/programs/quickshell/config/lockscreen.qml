import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.lock

// Session lock, run as its own one-shot instance by `quickshell-lock` (hypridle's lock_cmd):
// restarting the bar can't take it down, and the process exits once the session is unlocked.
ShellRoot {
    id: root

    // Idle locks only (quickshell-lock --grace): any input in the first QS_LOCK_GRACE seconds
    // unlocks without the password. The deadline is on the wall clock, which keeps running
    // through a suspend, so a sleep that starts inside the window can't carry it to the wake.
    readonly property real graceSeconds: parseFloat(Quickshell.env("QS_LOCK_GRACE")) || 0
    readonly property real graceUntil: Date.now() + graceSeconds * 1000
    property bool graceOpen: graceSeconds > 0

    LockContext {
        id: lockContext

        // Quit from here rather than on `locked` turning false: Quickshell 0.3.2 doesn't signal
        // that change when we make it, which left the process running and blocked the next lock
        // (quickshell-lock runs with --no-duplicate). The delay lets the unlock request reach the
        // compositor before the connection closes.
        onFinished: {
            lock.locked = false;
            quitTimer.start();
        }
    }

    WlSessionLock {
        id: lock

        locked: true

        // The compositor refused or dropped the lock (e.g. another locker holds the session).
        onLockedChanged: {
            if (!locked)
                quitTimer.start();
        }

        WlSessionLockSurface {
            color: Theme.ground

            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    Timer {
        interval: root.graceSeconds * 1000
        running: root.graceOpen
        onTriggered: root.graceOpen = false
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
            if (!isIdle && root.graceOpen && Date.now() < root.graceUntil && !lockContext.unlocking)
                lockContext.succeed();
        }
    }

    Timer {
        id: quitTimer

        interval: 200
        onTriggered: Qt.quit()
    }
}
