import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// What's playing, at the foot of the control panel: the cover, the track, its controls and the time
// so far, with the song as a track along the card's floor (a click seeks). The card takes the
// cover's own colour, its heaviest hue made dark and muted so enamel stays legible on it, and
// moves to the next cover's over a spatial move, so a track change goes colour to colour rather
// than through grey; a grey cover keeps the inset ground. The cover fades in once it has loaded
// (the music glyph holds its place), the title and artist fade in on a new track, and the play
// glyph grows into place whenever playback starts or stops, whatever started it.
Rectangle {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property string track: `${player?.trackTitle ?? ""}\n${player?.trackArtist ?? ""}`
    // Whether the panel is open: the position runs, and the cover can be read, only then.
    property bool shown: false
    // The card's ground: the cover's colour, or inset until one with a colour of its own loads.
    property color shade: Theme.inset

    signal playerFocused

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // The cover's main colour: its pixels binned by hue, each weighted by how vivid it is, and the
    // heaviest bin averaged, then set dark and muted. Near-greys have no hue worth taking, and a few
    // tinted pixels in a grey cover are not its colour.
    function shadeOf(data: var): color {
        const bins = [];
        for (let i = 0; i < data.length; i += 4) {
            const c = Qt.rgba(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255, 1);
            const weight = c.hsvSaturation * c.hsvValue;
            if (data[i + 3] < 128 || weight < 0.03)
                continue;
            const bin = Math.floor(Math.max(0, c.hslHue) * 12) % 12;
            bins[bin] = bins[bin] ?? {
                weight: 0,
                r: 0,
                g: 0,
                b: 0
            };
            bins[bin].weight += weight;
            bins[bin].r += c.r * weight;
            bins[bin].g += c.g * weight;
            bins[bin].b += c.b * weight;
        }
        const first = bins.filter(b => b).sort((a, b) => b.weight - a.weight)[0];
        if (!first || first.weight < data.length / 4 * 0.005)
            return Theme.inset;
        const c = Qt.rgba(first.r / first.weight, first.g / first.weight, first.b / first.weight, 1);
        return Qt.hsla(c.hslHue, Math.min(c.hslSaturation, 0.4), 0.17, 1);
    }

    // A 16px grab of the cover shown, for its colour; grabbing needs the panel on screen.
    function sample() {
        if (cover.status === Image.Ready && root.shown)
            cover.grabToImage(result => sampler.take(result), Qt.size(16, 16));
    }

    implicitHeight: 10 + 72 + 10 + 2 + 8
    radius: Theme.radiusInset
    color: shade

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationMove
            easing.type: Theme.easing
        }
    }

    onTrackChanged: textFade.restart()
    onPlayingChanged: pop.restart()
    onShownChanged: sampleTimer.restart()

    // MPRIS sends the position on seeks only; Quickshell works it out from the time since, when
    // asked.
    Timer {
        interval: 500
        repeat: true
        running: root.shown && root.playing
        onTriggered: root.player.positionChanged()
    }

    // The window maps a moment after `shown`.
    Timer {
        id: sampleTimer
        interval: 50
        onTriggered: root.sample()
    }

    // Never seen: a Canvas can't draw an Image item, so it draws the grab, which spares fetching
    // the cover twice.
    Canvas {
        id: sampler

        // The grab, kept while its URL is in use.
        property var grab: null

        function take(result: var) {
            if (grab)
                unloadImage(grab.url);
            grab = result;
            if (result)
                loadImage(result.url);
            requestPaint();
        }

        width: 16
        height: 16
        opacity: 0
        onImageLoaded: requestPaint()
        onAvailableChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!grab || !isImageLoaded(grab.url))
                return;
            ctx.drawImage(grab.url, 0, 0, width, height);
            root.shade = root.shadeOf(ctx.getImageData(0, 0, width, height).data);
        }
    }

    component Control: Rectangle {
        id: control

        property alias icon: glyph.text
        property alias glyph: glyph
        // "On": the play state while playing, gilt as everything that is on.
        property bool on: false

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: Theme.radiusRow
        // On the cover's colour a hover fill would be one more colour: the light lifts instead.
        color: on ? Theme.tint(Theme.gilt, area.containsMouse ? 0.16 : 0.1) : area.containsMouse ? Theme.tint(Theme.text, 0.08) : "transparent"
        opacity: enabled ? 1 : 0.5

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Icon {
            id: glyph
            anchors.centerIn: parent
            font.pixelSize: 16
            color: control.on ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }
    }

    RowLayout {
        x: 10
        y: 10
        width: parent.width - 20
        height: 72
        spacing: 12

        ClippingRectangle {
            implicitWidth: 72
            implicitHeight: 72
            radius: Theme.radiusRow
            color: Theme.tint(Theme.ground, 0.4)

            // The cover often arrives after the title: the glyph holds its place.
            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: Icons.music
                color: Theme.muted
                font.pixelSize: 26
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(144, 144)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                // The old colour stays while the next cover loads.
                onStatusChanged: {
                    if (status === Image.Ready)
                        root.sample();
                    else if (status !== Image.Loading)
                        root.shade = Theme.inset;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Media.focusPlayer();
                    root.playerFocused();
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                id: words
                Layout.fillWidth: true
                spacing: 2

                BarText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Unknown track"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                BarText {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || "Unknown artist"
                    color: Theme.text2
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                NumberAnimation {
                    id: textFade
                    target: words
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                Control {
                    icon: Icons.previous
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                Control {
                    id: playPause
                    icon: root.playing ? Icons.pause : Icons.play
                    on: root.playing
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                Control {
                    icon: Icons.next
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                BarText {
                    visible: root.length > 0
                    text: `${root.clock(root.player?.position ?? 0)} / ${root.clock(root.length)}`
                    color: Theme.text2
                    font.pixelSize: 11
                }
            }
        }
    }

    // The new symbol grows into place; nothing overshoots.
    NumberAnimation {
        id: pop
        target: playPause.glyph
        property: "scale"
        from: 0.6
        to: 1
        duration: Theme.durationState
        easing.type: Theme.easing
    }

    // The song along the floor, drawn like the day arc: what has played lit in text at 42%.
    Item {
        id: rail

        readonly property real progress: root.length > 0 ? Math.min(Math.max((root.player?.position ?? 0) / root.length, 0), 1) : 0

        x: 10
        y: parent.height - 8 - height
        width: parent.width - 20
        height: 2
        visible: root.length > 0

        Rectangle {
            anchors.fill: parent
            radius: 1
            color: Theme.tint(Theme.text, 0.14)
        }

        Rectangle {
            width: Math.round(rail.progress * rail.width)
            height: parent.height
            radius: 1
            color: Theme.tint(Theme.text, seekArea.containsMouse ? 0.7 : 0.42)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationState
                    easing.type: Theme.easing
                }
            }
        }

        // Taller than the track, so it is easy to hit.
        MouseArea {
            id: seekArea
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 12
            enabled: root.player?.canSeek ?? false
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => root.player.position = mouse.x / width * root.length
        }
    }
}
