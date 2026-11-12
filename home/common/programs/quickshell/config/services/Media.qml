pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland

// The player the bar follows: native clients (Sona and the other music apps, Plezy for Plex), then
// browser players on a music site; of those, whichever is playing, else the one that played last
// (pausing it doesn't hand the bar to another paused player), else the first in that order.
Singleton {
    id: root

    readonly property var nativeClients: ["cider", "spotify", "sona", "plezy"]
    readonly property var urlPatterns: ["music.apple.com", "open.spotify.com"]

    function clientName(player: MprisPlayer): string {
        return player.dbusName.replace("org.mpris.MediaPlayer2.", "").split(".")[0].toLowerCase();
    }

    // The native client a player is, or "": a bus name may carry it inside a longer one (Plezy
    // takes its program name, "com_edde746_plezy" from its Flatpak).
    function nativeName(player: MprisPlayer): string {
        const name = clientName(player);
        return nativeClients.find(client => name.includes(client)) ?? "";
    }

    readonly property var candidates: {
        const rank = p => {
            const native = nativeClients.indexOf(nativeName(p));
            if (native >= 0)
                return p.playbackState === MprisPlaybackState.Stopped ? -1 : native;
            return urlPatterns.some(pattern => String(p.metadata["xesam:url"] ?? "").includes(pattern)) ? nativeClients.length : -1;
        };
        return Mpris.players.values.filter(p => rank(p) >= 0).sort((a, b) => rank(a) - rank(b));
    }
    readonly property MprisPlayer playingNow: candidates.find(p => p.isPlaying) ?? null
    property MprisPlayer lastPlayed: null

    onPlayingNowChanged: {
        if (playingNow)
            lastPlayed = playingNow;
    }

    readonly property MprisPlayer player: playingNow ?? (candidates.includes(lastPlayed) ? lastPlayed : candidates[0] ?? null)

    // Playing or paused; stopped players have nothing to show.
    readonly property bool active: player !== null && player.playbackState !== MprisPlaybackState.Stopped

    // Bound at startup: the toplevel list fills in asynchronously, so a lookup made on first use comes back empty.
    readonly property var toplevels: ToplevelManager.toplevels.values

    // Bring the player's window forward, switching workspace if needed; a player with no window (e.g. only in the
    // tray) is asked to raise itself.
    function focusPlayer() {
        if (!player)
            return;
        const ids = [player.desktopEntry, clientName(player), nativeName(player)].filter(id => id).map(id => id.toLowerCase());
        // An app id may be reverse-DNS ("com.edde746.plezy") around the client's name.
        const toplevel = toplevels.find(t => ids.some(id => t.appId.toLowerCase() === id || t.appId.toLowerCase().endsWith(`.${id}`)));
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
