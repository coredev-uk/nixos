import QtQuick
import Quickshell
import qs.modules
import qs.services

ShellRoot {
    // Singletons start on first use; replay must be up for its key and to start the buffer at login.
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
