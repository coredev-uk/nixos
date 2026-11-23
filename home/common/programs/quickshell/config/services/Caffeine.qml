pragma Singleton

import Quickshell

// Session-wide keep-awake switch; each bar binds a Wayland idle inhibitor to it, stopping hypridle's timers.
Singleton {
    property bool enabled: false
}
