import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The desktop wallpaper, one background layer per screen: its own instance (quickshell-wallpaper,
// home/common/programs/quickshell/default.nix) so a bar restart never blanks the desktop.
// set-wallpaper (home/common/programs/hypr/paper.nix) points current.jpg at the new image and
// calls `change` with it; each screen keeps the old picture until the new one has decoded, then
// crossfades.
ShellRoot {
    id: root

    // Starts on whatever current.jpg points at; `change` replaces it with the image's own path,
    // which is unique per picture, so the image cache never serves a stale one.
    property string source: Quickshell.env("QS_WALLPAPER") ?? ""

    IpcHandler {
        target: "wallpaper"

        // Not `show`: the ipc CLI takes that word as its own subcommand.
        function change(path: string): void {
            root.source = path;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            // Index of the image on top; the other holds the previous picture until the fade ends.
            property int front: 0

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "wallpaper"
            color: "black"

            function load(path: string) {
                const current = pictures.itemAt(front);
                if (path === "" || !current || current.source.toString() === "file://" + path)
                    return;
                pictures.itemAt(1 - front).source = "file://" + path;
            }

            Connections {
                target: root
                function onSourceChanged() {
                    window.load(root.source);
                }
            }

            Repeater {
                id: pictures

                model: 2

                Image {
                    id: picture

                    required property int index

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    // Decoded at the screen's size, not the picture's (5K and up).
                    sourceSize.width: window.width
                    sourceSize.height: window.height
                    asynchronous: true
                    cache: false
                    z: index === window.front ? 1 : 0
                    opacity: index === 0 ? 1 : 0
                    // Set once: later pictures arrive through window.load, alternating images.
                    Component.onCompleted: {
                        if (index === 0 && root.source !== "")
                            source = "file://" + root.source;
                    }

                    onStatusChanged: {
                        if (status !== Image.Ready || index === window.front)
                            return;
                        fade.previous = pictures.itemAt(window.front);
                        window.front = index;
                        fade.target = picture;
                        fade.restart();
                    }
                }
            }

            NumberAnimation {
                id: fade

                property Image previous

                property: "opacity"
                from: 0
                to: 1
                duration: 1200
                easing.type: Easing.InOutCubic
                onFinished: {
                    if (previous) {
                        previous.opacity = 0;
                        previous.source = "";
                    }
                }
            }
        }
    }
}
