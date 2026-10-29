import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.lock

// Session lock, run as its own one-shot instance by `quickshell-lock` (hypridle's lock_cmd):
// restarting the bar can't take it down, and the process exits once the session is unlocked.
ShellRoot {
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
        id: quitTimer

        interval: 200
        onTriggered: Qt.quit()
    }
}
