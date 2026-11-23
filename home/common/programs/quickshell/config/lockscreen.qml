import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.lock

// Session lock, one-shot instance run by `quickshell-lock` (hypridle lock_cmd); exits once unlocked.
ShellRoot {
    LockContext {
        id: lockContext

        // Quit explicitly: Quickshell 0.3.2 doesn't signal `locked` going false when we set it, which
        // left the process running and blocked the next lock (--no-duplicate). The delay lets the
        // unlock reach the compositor first.
        onFinished: {
            lock.locked = false;
            quitTimer.start();
        }
    }

    WlSessionLock {
        id: lock

        locked: true

        // Compositor refused or dropped the lock (e.g. another locker holds the session).
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
