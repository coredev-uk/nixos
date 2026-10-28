import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.widgets

// Wallpaper picker (Super+Shift+P: `quickshell ipc -c bar call wallpapers toggle`). A carousel of
// slanted cards on the focused monitor, each the picture as it looks right now, over the
// highlighted one blurred full screen. Enter applies, Escape leaves the wallpaper as it was.
// Pictures and previews come from wallpaper-previews, switching from set-wallpaper
// (home/common/programs/hypr/paper.nix).
Scope {
    id: root

    property bool open: false
    // [{ id, image }] in the order of paper.nix's list.
    property var pictures: []
    property string current: ""
    property int selected: 0
    property string screenName: ""
    // Last line from the helpers, e.g. "Downloading The Lake (81 MB)".
    property string progress: ""
    property string error: ""

    readonly property bool loading: previews.running
    readonly property bool applying: apply.running

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function show() {
        screenName = Hyprland.focusedMonitor?.name ?? "";
        error = "";
        progress = "";
        open = true;
        previews.running = true;
    }

    // Leaves a running switch going in the background.
    function close() {
        open = false;
    }

    function move(delta: int) {
        if (pictures.length > 0 && !applying)
            selected = Math.max(0, Math.min(pictures.length - 1, selected + delta));
    }

    function choose() {
        const picture = pictures[selected];
        if (!picture || applying)
            return;
        if (picture.id === current) {
            close();
            return;
        }
        error = "";
        progress = "";
        apply.command = ["set-wallpaper", "set", picture.id];
        apply.running = true;
    }

    IpcHandler {
        target: "wallpapers"

        function toggle(): void {
            root.toggle();
        }
    }

    Process {
        id: previews

        command: ["wallpaper-previews"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.pictures = data.pictures;
                    root.current = data.current ?? "";
                    root.selected = Math.max(0, data.pictures.findIndex(p => p.id === root.current));
                } catch (e) {
                    root.error = "Couldn't load the wallpapers";
                }
            }
        }
        stderr: SplitParser {
            onRead: line => root.progress = line
        }
    }

    Process {
        id: apply

        stderr: SplitParser {
            onRead: line => root.progress = line
        }
        onExited: code => {
            if (code === 0) {
                root.current = root.pictures[root.selected]?.id ?? root.current;
                root.close();
            } else {
                root.error = "Couldn't switch the wallpaper";
            }
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: window

            readonly property real s: Math.max(0.75, height / 1080)

            screen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "wallpaper-picker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                id: content

                anchors.fill: parent
                focus: true
                opacity: 0

                Component.onCompleted: {
                    opacity = 1;
                    forceActiveFocus();
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Left:
                    case Qt.Key_H:
                        root.move(-1);
                        break;
                    case Qt.Key_Right:
                    case Qt.Key_L:
                        root.move(1);
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        root.choose();
                        break;
                    case Qt.Key_Escape:
                        root.close();
                        break;
                    default:
                        return;
                    }
                    event.accepted = true;
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                }

                // The highlighted picture full screen; the stack crossfades as the selection moves.
                Item {
                    id: backdrop

                    anchors.fill: parent
                    anchors.margins: -64
                    visible: false

                    Repeater {
                        model: root.pictures

                        Image {
                            required property var modelData
                            required property int index

                            anchors.fill: parent
                            source: `file://${modelData.image}`
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: index === root.selected ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 320
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                MultiEffect {
                    anchors.fill: backdrop
                    source: backdrop
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blurMax: 48
                    blur: 0.6
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                    opacity: 0.4
                }

                // Clicking outside the cards leaves without changing anything.
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                    onWheel: wheel => root.move(wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0 ? -1 : 1)
                }

                Item {
                    id: carousel

                    // Follows the selection smoothly; each card is laid out by its distance from it.
                    property real position: root.selected

                    readonly property real centerWidth: Math.round(600 * window.s)
                    readonly property real centerHeight: Math.round(420 * window.s)
                    readonly property real sideWidth: Math.round(170 * window.s)
                    readonly property real sideHeight: Math.round(340 * window.s)
                    readonly property real gap: Math.round(12 * window.s)

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Math.round(-30 * window.s)
                    height: centerHeight

                    Behavior on position {
                        NumberAnimation {
                            duration: 320
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: root.pictures

                        Item {
                            id: card

                            required property var modelData
                            required property int index

                            readonly property real offset: index - carousel.position
                            readonly property real distance: Math.abs(offset)
                            // 0 at the centre, 1 from the first neighbour outwards.
                            readonly property real side: Math.min(distance, 1)
                            readonly property real slant: height * 0.24

                            width: carousel.centerWidth + (carousel.sideWidth - carousel.centerWidth) * side
                            height: carousel.centerHeight + (carousel.sideHeight - carousel.centerHeight) * side - Math.max(distance - 1, 0) * 18 * window.s
                            x: carousel.width / 2 - width / 2 + Math.sign(offset) * (side * ((carousel.centerWidth + carousel.sideWidth) / 2 + carousel.gap) + Math.max(distance - 1, 0) * (carousel.sideWidth + carousel.gap))
                            y: (carousel.height - height) / 2
                            z: 100 - distance
                            opacity: Math.max(0, 1 - Math.max(distance - 1, 0) * 0.18)

                            Image {
                                id: image

                                anchors.fill: parent
                                source: `file://${card.modelData.image}`
                                sourceSize.width: 960
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }

                            Parallelogram {
                                id: mask

                                anchors.fill: parent
                                slant: card.slant
                                fill: "white"
                                layer.enabled: true
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: image
                                maskEnabled: true
                                maskSource: mask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1
                            }

                            // Side cards sit back a little.
                            Parallelogram {
                                anchors.fill: parent
                                slant: card.slant
                                fill: Theme.crust
                                opacity: 0.35 * card.side
                            }

                            Parallelogram {
                                anchors.fill: parent
                                slant: card.slant
                                stroke: Theme.blue
                                strokeWidth: Math.max(2, Math.round(3 * window.s))
                                opacity: 1 - card.side
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.index === root.selected)
                                        root.choose();
                                    else if (!root.applying)
                                        root.selected = card.index;
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: carousel.bottom
                    anchors.topMargin: Math.round(36 * window.s)
                    spacing: Math.round(12 * window.s)

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(12 * window.s)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.pictures[root.selected]?.id ?? ""
                            color: Theme.text
                            font.family: Theme.displayFontFamily
                            font.pixelSize: Math.round(30 * window.s)
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: (root.pictures[root.selected]?.id ?? "") === root.current && root.current !== ""
                            width: currentLabel.implicitWidth + Math.round(20 * window.s)
                            height: Math.round(26 * window.s)
                            radius: height / 2
                            color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.18)

                            BarText {
                                id: currentLabel

                                anchors.centerIn: parent
                                text: "Current"
                                color: Theme.blue
                                font.pixelSize: Math.round(13 * window.s)
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // Status while loading or switching, an empty note, else the keys.
                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (root.error !== "")
                                return root.error;
                            if (root.applying)
                                return root.progress !== "" ? `${root.progress}…` : "Applying…";
                            if (root.loading && root.pictures.length === 0)
                                return root.progress !== "" ? `${root.progress}… (first time only)` : "Loading wallpapers…";
                            if (root.pictures.length === 0)
                                return "No wallpapers found";
                            return "←  →  to browse     Enter to apply     Esc to close";
                        }
                        color: root.error !== "" ? Theme.red : Theme.subtext0
                        font.pixelSize: Math.round(15 * window.s)
                    }
                }
            }
        }
    }

    // A parallelogram leaning right by `slant` at the top: the cards' shape, as a mask, a tint
    // or an outline.
    component Parallelogram: Shape {
        id: shape

        property real slant
        property color fill: "transparent"
        property color stroke: "transparent"
        property real strokeWidth: 0

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: shape.fill
            strokeColor: shape.stroke
            strokeWidth: shape.strokeWidth
            joinStyle: ShapePath.RoundJoin
            startX: shape.slant
            startY: 0

            PathLine {
                x: shape.width
                y: 0
            }
            PathLine {
                x: shape.width - shape.slant
                y: shape.height
            }
            PathLine {
                x: 0
                y: shape.height
            }
            PathLine {
                x: shape.slant
                y: 0
            }
        }
    }
}
