pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// AirPlay 2 speakers through OwnTone's JSON API (home/common/programs/airplay.nix): which exist,
// which are chosen, and pairing. Audio reaches OwnTone through the "airplay" PipeWire sink;
// OwnTone plays it on every selected speaker. Only polled while someone is looking. While
// casting, the bar's player (services/Media.qml) is passed on as the track the devices show.
Singleton {
    id: root

    readonly property string api: "http://127.0.0.1:3689/api"
    // Set by the Cast view while it's open.
    property bool watching: false
    // OwnTone answered the last request.
    property bool available: false
    // Some request has answered, so `available` means something.
    property bool known: false
    // Speakers whose code prompt was cancelled; picking one again asks again.
    property var pinDismissedIds: []
    // Speaker ids picked in the Cast view. OwnTone drops a speaker from its selection when it
    // fails to connect, so the difference shows which ones failed. null until the first answer.
    property var chosenIds: null
    // [{ id, name, chosen, failed, needsPin }] by name.
    property var speakers: []
    readonly property var chosen: speakers.filter(speaker => speaker.chosen)
    // The last failure, for the Cast view.
    property string error: ""
    // The sink that feeds OwnTone; casting means it is the default output.
    readonly property PwNode sink: Pipewire.nodes.values.find(node => node.name === "airplay") ?? null
    readonly property bool casting: sink !== null && Pipewire.defaultAudioSink === sink
    // Where stop() goes back to.
    property PwNode lastLocalOutput: null
    readonly property var player: Media.player
    // Changes with the track; the periodic resend covers OwnTone (re)starting the pipe.
    readonly property string track: [player?.trackTitle, player?.trackArtist, player?.trackAlbum, player?.trackArtUrl].join("\n")

    function request(method: string, path: string, body: var, done: var) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && done)
                done(xhr.status, xhr.responseText);
        };
        xhr.open(method, api + path);
        xhr.send(body === undefined ? null : JSON.stringify(body));
    }

    function refresh() {
        request("GET", "/outputs", undefined, (status, text) => {
            available = status === 200;
            known = true;
            if (!available) {
                speakers = [];
                return;
            }
            // OwnTone also lists Chromecasts; the Cast view sends screens there instead.
            const outputs = JSON.parse(text).outputs.filter(output => output.type.startsWith("AirPlay"));
            // Speakers OwnTone selected itself (restored after a restart, or picked elsewhere)
            // count as chosen too.
            const selectedIds = outputs.filter(output => output.selected).map(output => output.id);
            chosenIds = (chosenIds ?? []).concat(selectedIds.filter(id => !(chosenIds ?? []).includes(id)));
            speakers = outputs.map(output => {
                const chosen = chosenIds.includes(output.id);
                // A TV asking for a one-time code fails its first connection; so does a speaker
                // refusing this computer (the HomePod's access setting).
                const failed = chosen && !output.selected;
                return {
                    id: output.id,
                    name: output.name,
                    chosen,
                    failed,
                    needsPin: (output.needs_auth_key || failed) && !pinDismissedIds.includes(output.id)
                };
            }).sort((a, b) => a.name.localeCompare(b.name));
        });
    }

    // Plays on exactly these speakers (none stops).
    function select(ids: var) {
        chosenIds = ids;
        error = "";
        request("PUT", "/outputs/set", {
            outputs: ids
        }, status => {
            if (status !== 204)
                error = "Couldn't change the AirPlay speakers";
            refresh();
        });
    }

    function toggle(speaker: var) {
        const ids = (chosenIds ?? []).filter(id => id !== speaker.id);
        if (!speaker.chosen) {
            ids.push(speaker.id);
            pinDismissedIds = pinDismissedIds.filter(id => id !== speaker.id);
        }
        select(ids);
    }

    // Hides the code prompt without picking the speaker; a chosen one that failed is dropped.
    function dismissPin(speaker: var) {
        pinDismissedIds = pinDismissedIds.concat([speaker.id]);
        if (speaker.chosen)
            select((chosenIds ?? []).filter(id => id !== speaker.id));
        else
            refresh();
    }

    // Streams that follow the default output move with it.
    function playOn(node: PwNode) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    // Back to this computer's last output (the first by name if there was none), speakers off.
    function stop() {
        select([]);
        const local = lastLocalOutput ?? Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio && node !== sink).sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name))[0];
        if (local)
            playOn(local);
    }

    // Picking a speaker routes the computer's audio into OwnTone; the last one off routes it back.
    // A speaker still chosen from last time resumes instead of turning off.
    function toggleSpeaker(speaker: var) {
        if (speaker.chosen && !casting && sink) {
            playOn(sink);
            return;
        }
        const remaining = chosen.filter(other => other.id !== speaker.id).length;
        toggle(speaker);
        if (!speaker.chosen && sink && !casting)
            playOn(sink);
        else if (speaker.chosen && remaining === 0)
            stop();
    }

    // The code shown on the device's screen; once paired, it is selected again.
    function submitPin(speaker: var, pin: string) {
        error = "";
        request("PUT", `/outputs/${speaker.id}`, {
            pin
        }, status => {
            if (status !== 204)
                error = `${speaker.name} didn't accept the code`;
            select(chosenIds ?? []);
        });
    }

    function sendMetadata() {
        if (!casting || !player || metadata.running)
            return;
        metadata.command = ["airplay-metadata", player.trackTitle ?? "", player.trackArtist ?? "", player.trackAlbum ?? "", player.trackArtUrl ?? "", String(Math.round((player.positionSupported ? player.position : 0) * 1000)), String(Math.round((player.lengthSupported ? player.length : 0) * 1000))];
        metadata.running = true;
    }

    function rememberOutput() {
        const output = Pipewire.defaultAudioSink;
        if (output && output !== sink)
            lastLocalOutput = output;
    }

    onTrackChanged: sendMetadata()
    onCastingChanged: sendMetadata()

    Component.onCompleted: {
        rememberOutput();
        refresh();
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            root.rememberOutput();
        }
    }

    Timer {
        running: root.watching
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        running: root.casting && root.player !== null
        interval: 5000
        repeat: true
        onTriggered: root.sendMetadata()
    }

    Process {
        id: metadata
    }
}
