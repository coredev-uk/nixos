import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// Now-playing card: album art fills the background behind a scrim, with track text and controls on top.
// Text colours follow the artwork: light art gets a light scrim and dark text, dark art the reverse,
// and the accent is the most colourful artwork colour that stays legible.
// Clicking anywhere but the controls focuses the player's window.
ClippingRectangle {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool hasArt: art.status === Image.Ready && quantizer.colors.length > 0

    signal playerFocused

    readonly property color artAverage: {
        const colors = quantizer.colors;
        if (colors.length === 0)
            return Theme.inset;
        const sum = colors.reduce((acc, c) => [acc[0] + c.r, acc[1] + c.g, acc[2] + c.b], [0, 0, 0]);
        return Qt.rgba(sum[0] / colors.length, sum[1] / colors.length, sum[2] / colors.length, 1);
    }
    readonly property bool lightArt: hasArt && luminance(artAverage) > 0.5
    readonly property color scrim: lightArt ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0, 0, 0, 0.45)
    // What the text actually sits on: the artwork average seen through the scrim.
    readonly property color background: hasArt ? blend(artAverage, scrim) : Theme.inset
    readonly property color textColor: lightArt ? Theme.ground : Theme.text
    readonly property color accent: hasArt ? pickAccent(quantizer.colors, background) : Theme.fill

    // WCAG relative luminance and contrast ratio.
    function luminance(c: color): real {
        const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
    }

    function contrast(a: color, b: color): real {
        const la = luminance(a);
        const lb = luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    function blend(base: color, over: color): color {
        const a = over.a;
        return Qt.rgba(base.r * (1 - a) + over.r * a, base.g * (1 - a) + over.g * a, base.b * (1 - a) + over.b * a, 1);
    }

    // Most colourful artwork colour (by chroma; HSL saturation rates pale pastels as vivid), pushed
    // lighter/darker until it reads at 4.5:1 (WCAG AA) against the background.
    function pickAccent(colors: list<color>, bg: color): color {
        const chroma = c => Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b);
        const candidates = Array.from(colors).sort((a, b) => chroma(b) - chroma(a));
        for (const candidate of candidates) {
            let c = candidate;
            for (let i = 0; i < 8 && contrast(c, bg) < 4.5; i++)
                c = lightArt ? Qt.darker(c, 1.25) : Qt.lighter(c, 1.25);
            if (contrast(c, bg) >= 4.5)
                return c;
        }
        return textColor;
    }

    // ColorQuantizer only reads local files, so snapshot the (possibly remote) artwork to the cache first.
    // Grabbing needs a visible window, and the popup's window only shows while the panel is open.
    property int snapshotSlot: 0
    readonly property bool windowVisible: Window.window?.visible ?? false

    onWindowVisibleChanged: sampleTimer.restart()

    Timer {
        id: sampleTimer
        interval: 50
        onTriggered: root.sampleArt()
    }

    function sampleArt() {
        if (art.status !== Image.Ready || !root.windowVisible)
            return;
        art.grabToImage(result => {
            const path = Quickshell.cachePath(`media-art-${root.snapshotSlot}.png`);
            root.snapshotSlot = 1 - root.snapshotSlot;
            if (result.saveToFile(path))
                quantizer.source = `file://${path}`;
        }, Qt.size(32, 32));
    }

    implicitHeight: Math.max(90, overlay.implicitHeight + 20)
    radius: Theme.radiusInset
    color: Theme.inset

    ColorQuantizer {
        id: quantizer
        depth: 3 // 8 colours, enough to pick out small accents
        rescaleSize: 32
    }

    Image {
        id: art
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        sourceSize.width: 640
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        onStatusChanged: {
            if (status === Image.Ready)
                root.sampleArt();
        }
    }

    // Keeps the text legible over busy artwork.
    Rectangle {
        anchors.fill: parent
        visible: root.hasArt
        color: root.scrim
    }

    // Below the overlay so the control buttons keep their own clicks.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Media.focusPlayer();
            root.playerFocused();
        }
    }

    component MediaButton: Rectangle {
        id: button

        property alias icon: label.text
        property color accent

        signal clicked

        implicitWidth: label.implicitWidth + 24
        implicitHeight: label.implicitHeight + 12
        radius: Theme.radiusRow
        color: Theme.tint(accent, area.containsMouse ? 0.16 : 0.1)
        opacity: enabled ? 1 : 0.5

        Icon {
            id: label
            anchors.centerIn: parent
            color: button.accent
            font.pixelSize: 18
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    ColumnLayout {
        id: overlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 10
        spacing: 4

        ScrollingText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Unknown Track"
            color: root.accent
            font.pixelSize: 13
            font.bold: true
        }

        ScrollingText {
            Layout.fillWidth: true
            text: [root.player?.trackArtist, root.player?.trackAlbum].filter(part => part).join(" - ") || "Unknown Artist"
            color: root.textColor
            opacity: 0.9
            font.pixelSize: 12
        }

        Row {
            spacing: 20

            MediaButton {
                icon: Icons.previous
                accent: root.accent
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            MediaButton {
                icon: root.player?.isPlaying ? Icons.pause : Icons.play
                accent: root.accent
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }

            MediaButton {
                icon: Icons.next
                accent: root.accent
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }
    }
}
