import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.widgets

RowLayout {
    id: root

    // Native music clients take priority, then browser players on a music site.
    readonly property var nativeClients: ["cider", "spotify"]
    readonly property var urlPatterns: ["music.apple.com", "open.spotify.com"]

    function clientName(player: MprisPlayer): string {
        return player.dbusName.replace("org.mpris.MediaPlayer2.", "").split(".")[0].toLowerCase();
    }

    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        for (const name of nativeClients) {
            const native = players.find(p => clientName(p) === name && p.playbackState !== MprisPlaybackState.Stopped);
            if (native)
                return native;
        }
        return players.find(p => urlPatterns.some(pattern => String(p.metadata["xesam:url"] ?? "").includes(pattern))) ?? null;
    }

    visible: player?.isPlaying ?? false
    spacing: 6

    ClippingRectangle {
        visible: (root.player?.trackArtUrl ?? "") !== ""
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: Theme.surface0

        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: 40
            sourceSize.height: 40
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    BarText {
        Layout.maximumWidth: 600
        text: `${root.player?.trackTitle ?? ""} - ${root.player?.trackArtist ?? ""}`
        elide: Text.ElideRight
    }
}
