pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The music player the bar follows: native clients first, then browser players on a music site.
Singleton {
    id: root

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

    // Playing or paused; stopped players have nothing to show.
    readonly property bool active: player !== null && player.playbackState !== MprisPlaybackState.Stopped
}
