import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Desktop wallpaper, one background layer per screen, in its own instance (quickshell-wallpaper)
// so bar restarts never blank it. set-wallpaper (hypr/paper.nix) calls `change`; each screen keeps
// the old picture until the new one has decoded, then crossfades.
ShellRoot {
    id: root

    // `change` sets the image's own unique path so the image cache never serves a stale one.
    property string source: Quickshell.env("QS_WALLPAPER") ?? ""

    IpcHandler {
        target: "wallpaper"

        // Not `show`: the ipc CLI treats it as a subcommand.
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
                    // Decode at screen size (pictures are 5K+).
                    sourceSize.width: window.width
                    sourceSize.height: window.height
                    asynchronous: true
                    cache: false
                    z: index === window.front ? 1 : 0
                    opacity: index === 0 ? 1 : 0
                    // Later pictures arrive via window.load.
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
