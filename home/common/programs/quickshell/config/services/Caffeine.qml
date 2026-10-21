pragma Singleton

import Quickshell

// Session-wide "keep awake" switch; each bar holds a Wayland idle inhibitor bound to it, which stops hypridle's timers.
Singleton {
    property bool enabled: false
}
