pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland

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

    // Bound at startup: the toplevel list fills in asynchronously, so a lookup made on first use comes back empty.
    readonly property var toplevels: ToplevelManager.toplevels.values

    // Bring the player's window forward, switching workspace if needed; a player with no window (e.g. only in the
    // tray) is asked to raise itself.
    function focusPlayer() {
        if (!player)
            return;
        const ids = [player.desktopEntry, clientName(player)].filter(id => id).map(id => id.toLowerCase());
        const toplevel = toplevels.find(t => ids.includes(t.appId.toLowerCase()));
        // Hyprland doesn't reliably honour a foreign-toplevel activate, so focus through its own dispatcher.
        const address = Hyprland.toplevels.values.find(h => h.wayland === toplevel)?.address.replace(/^0x/, "");
        if (toplevel && address)
            Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ window = "address:0x${address}" })` : `focuswindow address:0x${address}`);
        else if (toplevel)
            toplevel.activate();
        else if (player.canRaise)
            player.raise();
    }
}
