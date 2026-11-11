pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Sona's lyrics for now playing's popup (modules/MediaPopup.qml). `sona lyrics --follow --json`
// prints one JSON object each time the line, the song or the playback state changes, from Sona's
// own lyrics sources and cache (docs/cli.md in sona-go); `sona lyrics --json` gives the whole
// song once. They run only while the popup is open on Sona, so nothing is spawned otherwise.
Singleton {
    id: root

    // Set by the popup while it is open.
    property bool watched: false
    readonly property bool sona: Media.player !== null && Media.clientName(Media.player) === "sona"
    readonly property bool wanted: watched && sona

    // "loading", "ready" (timed lines), "plain" (lyrics without timing) or "none".
    property string status: "loading"
    // The playing song's timed lyrics, every line in order: [{ start, text }]; [] until fetched.
    property var lines: []
    // The line being sung, -1 while the voice rests, before the first line and after the last.
    property int index: -1
    // The line the popup centres: the one being sung, else the one coming next, else the last.
    readonly property int focus: {
        if (lines.length === 0)
            return -1;
        if (index >= 0 && index < lines.length)
            return index;
        if (nextStart >= 0) {
            const next = lines.findIndex(l => l.start === nextStart);
            if (next >= 0)
                return next;
        }
        return lines.length - 1;
    }
    property real nextStart: -1
    property string trackId: ""
    // The song the lyrics follow, to tell when Sona's MPRIS metadata has moved on before them.
    property string title: ""

    function clear() {
        status = "loading";
        lines = [];
        index = -1;
        nextStart = -1;
        trackId = "";
        title = "";
    }

    onWantedChanged: {
        follow.running = wanted;
        if (!wanted) {
            retry.stop();
            clear();
        }
    }

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
                }
                if (timed && root.trackId === "" && id !== "") {
                    root.trackId = id;
                    all.running = true;
                }
                root.status = now.lyrics === "loading" ? "loading" : timed ? "ready" : now.lyrics === "ready" ? "plain" : "none";
                root.title = now.track?.title ?? "";
                root.nextStart = now.next?.start ?? -1;
                root.index = now.index ?? -1;
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
    // starts again for the one playing.
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
                root.lines = (lyrics?.lines ?? []).map(l => ({
                            start: l.start,
                            text: l.text ?? ""
                        }));
            }
        }
    }
}
