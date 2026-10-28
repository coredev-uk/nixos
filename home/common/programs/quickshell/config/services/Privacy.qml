pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Apps currently capturing the microphone, camera, screen or system audio, read from the PipeWire
// graph: a capture stream (Stream/Input/*) with an active link from the device it records. Also
// where audio is being cast: the AirPlay speakers playing this computer's output.
// Each list holds { name, icon } entries, one per app or speaker.
Singleton {
    id: root

    readonly property var groups: Pipewire.linkGroups.values
    readonly property var captures: {
        // Desktop entries load asynchronously; reading them re-resolves names and icons once they arrive.
        DesktopEntries.applications.values;
        const found = {
            microphone: [],
            camera: [],
            screen: [],
            systemAudio: []
        };
        for (const group of groups) {
            const kind = captureKind(group);
            if (kind === "")
                continue;
            const app = appEntry(group.target);
            if (!found[kind].some(entry => entry.name === app.name))
                found[kind].push(app);
        }
        return found;
    }
    readonly property var microphone: captures.microphone
    readonly property var camera: captures.camera
    readonly property var screen: captures.screen
    readonly property var systemAudio: captures.systemAudio
    // Screen casts already show up above: GNOME Network Displays records the screen and its own
    // sink like any other app.
    readonly property var cast: AirPlay.casting ? AirPlay.chosen.filter(speaker => !speaker.failed).map(speaker => ({
                name: speaker.name,
                icon: ""
            })) : []
    readonly property bool active: microphone.length + camera.length + screen.length + systemAudio.length + cast.length > 0

    // Which device a link group records from, or "" if it isn't an app actively capturing one.
    function captureKind(group: PwLinkGroup): string {
        // Paused/negotiating links (corked streams, idle portals) aren't recording anything yet.
        if (group.state !== PwLinkState.Active || !group.source || !group.target)
            return "";
        const consumer = group.target.properties;
        const consumerClass = consumer["media.class"] ?? "";
        if (!consumerClass.startsWith("Stream/Input/") || ignored(consumer))
            return "";
        const producer = group.source.properties;
        const producerClass = producer["media.class"] ?? "";
        if (consumerClass === "Stream/Input/Audio") {
            if (producerClass.startsWith("Audio/Source") || producerClass === "Audio/Duplex")
                return "microphone";
            // A sink's monitor ports, or another app's output stream tapped directly.
            if (producerClass === "Audio/Sink" || producerClass === "Stream/Output/Audio")
                return "systemAudio";
        } else if (consumerClass === "Stream/Input/Video" && producerClass === "Video/Source") {
            // Screencasts are produced by the desktop portal; any other video source is a camera.
            const portal = /xdg-desktop-portal/.test(producer["node.name"] ?? "") || /xdg-desktop-portal/.test(producer["application.process.binary"] ?? "");
            return portal ? "screen" : "camera";
        }
        return "";
    }

    function ignored(props: var): bool {
        // Level meters (pavucontrol's peak detection, passive streams) watch levels without recording.
        if (props["stream.monitor"] === "true" || (props["node.passive"] ?? "false") !== "false")
            return true;
        // Our own streams, so the bar never flags itself.
        if (Number(props["application.process.id"]) === Quickshell.processId)
            return true;
        // Loopbacks, filter chains and echo cancellation live in the PipeWire daemons: routing, not an app.
        return /^(pipewire|pipewire-pulse|wireplumber)$/.test(props["application.process.binary"] ?? "");
    }

    // ".Discord-wrapped" -> Discord, "firefox" -> Firefox.
    function prettify(name: string): string {
        const bare = name.replace(/^\./, "").replace(/-wrapped$/, "");
        return bare.charAt(0).toUpperCase() + bare.slice(1);
    }

    // Stream names are often the audio library's ("WEBRTC VoiceEngine" for Discord, "PipeWire ALSA [Cider]"),
    // so prefer the sandbox app id and the process binary over application.name.
    function appEntry(node: PwNode): var {
        const props = node.properties;
        const appName = props["application.name"] ?? "";
        const bracketed = appName.match(/\[(.+)\]/);
        const portalEntry = DesktopEntries.byId(props["pipewire.access.portal.app_id"] ?? "");
        const binary = props["application.process.binary"] ?? "";
        const name = bracketed ? bracketed[1] : portalEntry?.name ?? (binary !== "" ? prettify(binary) : appName !== "" ? appName : prettify(node.name));
        const entry = portalEntry ?? DesktopEntries.heuristicLookup(name);
        const iconName = entry?.icon ?? props["application.icon-name"] ?? "";
        return {
            name: name,
            icon: iconName !== "" ? Quickshell.iconPath(iconName, true) : ""
        };
    }

    // Node properties and link states are only fetched for bound objects.
    PwObjectTracker {
        objects: {
            const objects = [];
            for (const group of root.groups)
                objects.push(group, group.source, group.target);
            return objects.filter(object => object !== null);
        }
    }
}
