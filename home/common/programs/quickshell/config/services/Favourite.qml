pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether the song playing in Sona is one of its Apple Music favourites, for the heart on what's
// playing (modules/MediaPanel.qml): `sona like status --json` asks, `sona like toggle --json`
// switches it ({ track: { id, … }, liked }, docs/cli.md in sona-go). Only Sona has favourites, and
// it is asked only while what's playing is on screen (watch()), again on a new song, so nothing is
// spawned otherwise. A switch shows at once and goes back if Sona refuses it (signed out of Apple
// Music, or not running).
Singleton {
    id: root

    readonly property bool sona: Media.player !== null && Media.clientName(Media.player) === "sona"
    property int watchers: 0
    readonly property bool wanted: watchers > 0 && sona
    // The song asked about, so a late answer for the last song isn't taken for this one.
    readonly property string song: sona ? `${Media.player.trackTitle}\n${Media.player.trackArtist}` : ""
    // true or false once Sona has said, null before then or when it can't.
    property var liked: null

    function watch(on: bool) {
        watchers = Math.max(0, watchers + (on ? 1 : -1));
    }

    function refresh() {
        if (wanted && !asker.running && !toggler.running)
            asker.running = true;
    }

    function toggle() {
        if (!sona || liked === null || toggler.running)
            return;
        // Shown at once; Sona's answer settles it either way.
        liked = !liked;
        toggler.running = true;
    }

    // Sona's answer to either command, for the song it was asked about: true, false, or null when
    // it gave none (not running, signed out of Apple Music) or the song has changed since.
    function answer(text: string, forSong: string): var {
        if (forSong !== song)
            return null;
        try {
            const parsed = JSON.parse(text);
            return typeof parsed.liked === "boolean" ? parsed.liked : null;
        } catch (e) {
            return null;
        }
    }

    onWantedChanged: {
        if (wanted)
            refresh();
    }
    onSongChanged: {
        liked = null;
        refresh();
    }

    Process {
        id: asker

        property string forSong

        command: ["sona", "like", "status", "--json"]
        onStarted: forSong = root.song
        stdout: StdioCollector {
            onStreamFinished: {
                if (asker.forSong === root.song)
                    root.liked = root.answer(text, asker.forSong);
            }
        }
    }

    Process {
        id: toggler

        property string forSong

        command: ["sona", "like", "toggle", "--json"]
        onStarted: forSong = root.song
        // A refusal keeps the switch shown only until Sona is asked again what it holds.
        stdout: StdioCollector {
            onStreamFinished: {
                const liked = root.answer(text, toggler.forSong);
                if (liked !== null)
                    root.liked = liked;
            }
        }
        onExited: code => {
            if (code !== 0)
                Qt.callLater(root.refresh);
        }
    }
}
