pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The line Sona is singing, for the bar's now playing. `sona lyrics --follow --json` prints one
// JSON object each time the line, the song or the playback state changes, from Sona's own lyrics
// sources and cache (docs/cli.md in sona-go). It runs only while the bar follows Sona, so nothing
// is spawned for other players or while Sona is closed.
Singleton {
    id: root

    readonly property bool wanted: Media.player !== null && Media.clientName(Media.player) === "sona"

    // The line being sung, "" while the voice rests, before the first line, for plain (untimed)
    // lyrics and for a song without lyrics.
    property string line: ""
    // Every line of the playing song's timed lyrics, so the bar can hold one width for the whole
    // song instead of moving with each line; [] until fetched and for a song without them.
    property var lines: []
    property string trackId: ""
    // The song the lyrics follow, to tell when Sona's MPRIS metadata has moved on before them.
    property string title: ""
    readonly property bool following: follow.running
    // False from a song change until it is known whether the song has timed lyrics and, if it
    // does, until their lines are in: the bar moves to the new song's width once, not twice.
    property bool settled: true
    property bool fetched: false

    function clear() {
        line = "";
        lines = [];
        trackId = "";
        title = "";
        fetched = false;
        settled = true;
    }

    onWantedChanged: {
        follow.running = wanted;
        if (!wanted)
            clear();
    }
    Component.onCompleted: follow.running = wanted

    Process {
        id: follow
        command: ["sona", "lyrics", "--follow", "--json"]
        stdout: SplitParser {
            onRead: data => {
                let now;
                try {
                    now = JSON.parse(data);
                } catch (e) {
                    return;
                }
                const id = now.track?.id ?? "";
                const timed = now.lyrics === "ready" && now.synced;
                if (id !== root.trackId) {
                    root.lines = [];
                    root.trackId = "";
                    root.fetched = false;
                }
                if (timed && root.trackId === "" && id !== "") {
                    root.trackId = id;
                    all.running = true;
                }
                root.settled = now.lyrics !== "loading" && (!timed || root.fetched);
                root.title = now.track?.title ?? "";
                root.line = now.text ?? "";
            }
        }
        // 3 when Sona isn't running yet, 0 when it quit.
        onExited: {
            root.clear();
            if (root.wanted)
                retry.restart();
        }
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: {
            if (root.wanted)
                follow.running = true;
        }
    }

    // The whole song's lines, once per song. A fetch that finishes for a song already skipped
    // starts again for the one playing; one that fails leaves the lines empty and settles anyway.
    Process {
        id: all
        command: ["sona", "lyrics", "--json"]
        stdout: StdioCollector {
            id: allOut
            onStreamFinished: {
                let lyrics = null;
                try {
                    lyrics = JSON.parse(allOut.text);
                } catch (e) {}
                if (root.trackId === "")
                    return;
                if (lyrics && (lyrics.track?.id ?? "") !== root.trackId) {
                    Qt.callLater(() => all.running = true);
                    return;
                }
                root.lines = (lyrics?.lines ?? []).map(l => l.text).filter(t => t);
                root.fetched = true;
                root.settled = true;
            }
        }
    }
}
