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

    function clear() {
        line = "";
        lines = [];
        trackId = "";
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
                if (id !== root.trackId) {
                    root.lines = [];
                    root.trackId = "";
                }
                if (now.lyrics === "ready" && now.synced && root.trackId === "" && id !== "") {
                    root.trackId = id;
                    all.running = true;
                }
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

    // The whole song's lines, once per song.
    Process {
        id: all
        command: ["sona", "lyrics", "--json"]
        stdout: StdioCollector {
            id: allOut
            onStreamFinished: {
                try {
                    const lyrics = JSON.parse(allOut.text);
                    if ((lyrics.track?.id ?? "") === root.trackId)
                        root.lines = lyrics.lines.map(l => l.text).filter(t => t);
                } catch (e) {}
            }
        }
    }
}
