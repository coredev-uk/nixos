import QtQuick
import Quickshell.Widgets
import qs.common

// A player's cover in a rounded well, and its colour for the surface it sits on (what's playing
// in the control panel, now playing's card). The muted music glyph holds the cover's place until
// it loads, then the cover fades in over State. `shade` is the cover's heaviest hue, made dark and
// muted so enamel and text2 stay legible on it: pixels binned by hue, each weighted by how vivid
// it is, the heaviest bin averaged, its saturation held to 40% and lightness to 17%. A grey cover
// (no hue worth taking, or only a few tinted pixels) gives `ground`; the old shade stays while the
// next cover loads, so a track change goes colour to colour. Reading the colour grabs the cover,
// which needs its window on screen: `shown` says when it is.
ClippingRectangle {
    id: root

    property url source
    property bool shown: false
    // What the shade falls back to, the surface's own ground.
    property color ground: Theme.inset
    property color shade: ground
    property int glyphSize: 26

    signal clicked

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
            return ground;
        const c = Qt.rgba(first.r / first.weight, first.g / first.weight, first.b / first.weight, 1);
        return Qt.hsla(c.hslHue, Math.min(c.hslSaturation, 0.4), 0.17, 1);
    }

    // A 16px grab of the cover shown, for its colour.
    function sample() {
        if (cover.status === Image.Ready && shown)
            cover.grabToImage(result => sampler.take(result), Qt.size(16, 16));
    }

    radius: Theme.radiusRow
    color: Theme.tint(Theme.ground, 0.4)

    // The window maps a moment after `shown`.
    onShownChanged: sampleTimer.restart()

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

    // The cover often arrives after the title: the glyph holds its place.
    Icon {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        text: Icons.music
        color: Theme.muted
        font.pixelSize: root.glyphSize
    }

    Image {
        id: cover
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        onStatusChanged: {
            if (status === Image.Ready)
                root.sample();
            else if (status !== Image.Loading)
                root.shade = root.ground;
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
        onClicked: root.clicked()
    }
}
