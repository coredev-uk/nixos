import QtQuick
import qs.widgets

// Now playing's popup: the card (NowPlayingCard.qml) hung under the bar's track.
BarPopup {
    id: root

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight + gap
    dismissible: true

    NowPlayingCard {
        id: card
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        active: root.visible
        onPlayerFocused: root.visible = false
    }
}
