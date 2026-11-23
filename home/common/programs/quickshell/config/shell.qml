import QtQuick
import Quickshell
import qs.modules
import qs.services

ShellRoot {
    // Singletons start on first use; Replay must start the buffer at login and own its key.
    Component.onCompleted: Replay.refresh()

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    WallpaperPicker {}
    NotificationPopups {}
    Osd {}
    ScreenshotPopup {}
    PolkitDialog {}
    PassQuickAccess {}
}
