import QtQuick
import qs.widgets

// Now playing's popup: the strip (NowPlayingStrip.qml) hung under the bar's track.
BarPopup {
    id: root

    implicitWidth: strip.implicitWidth
    implicitHeight: strip.implicitHeight + gap
    dismissible: true

    NowPlayingStrip {
        id: strip
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        active: root.visible
        onPlayerFocused: root.visible = false
    }
}
