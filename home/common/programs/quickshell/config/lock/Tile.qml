import QtQuick
import qs.common

// Rounded tile the password card's side panels are built from.
Rectangle {
    // Layout scale from the surface (1 at 1080p).
    property real s: 1

    radius: Math.round(18 * s)
    color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.7)
}
