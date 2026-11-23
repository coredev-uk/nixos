import QtQuick
import Quickshell.Widgets
import qs.common

// A player's cover in a rounded well plus a `shade` for the surface behind it. The muted music
// glyph holds the place until the cover loads. `shade` is the cover's heaviest hue (pixels binned
// by hue, weighted by vividness) with saturation capped at 40% and lightness at 17% so enamel/text2
// stay legible; grey covers give `ground`; the old shade stays while the next cover loads. Reading
// the colour grabs the cover, which needs its window on screen (`shown`).
ClippingRectangle {
    id: root

    property url source
    property bool shown: false
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

    function sample() {
        if (cover.status === Image.Ready && shown)
            cover.grabToImage(result => sampler.take(result), Qt.size(16, 16));
    }

    radius: Theme.radiusRow
    color: Theme.tint(Theme.ground, 0.4)

    onShownChanged: sampleTimer.restart()

    Timer {
        id: sampleTimer
        interval: 50
        onTriggered: root.sample()
    }

    // Never seen: a Canvas can't draw an Image item, so it draws the grab, saving a second fetch.
    Canvas {
        id: sampler

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
