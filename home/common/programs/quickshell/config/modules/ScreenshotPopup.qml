import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

// What the Print key leaves behind, driven over IPC by quickshell-screenshot (scripts/screenshot.sh,
// `quickshell ipc -c bar call screenshot taken FILE`) once the area is on the clipboard. A floating
// card in the bottom-right corner of the focused monitor, away from the notification popups at the
// top, with the picture and two actions: Edit (satty) and Save (the XDG screenshots directory).
// Leaves after a few seconds unless hovered. The capture is a private file in $XDG_RUNTIME_DIR that
// goes with the popup; Hyprland leaves this layer alone (no_anim, like the OSD), the motion is
// only this.
Scope {
    id: root

    // Captures only ever sit here (the script's `dir`); anything else sent over IPC is refused.
    readonly property string dir: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-screenshot/`
    property string path: ""
    property bool shown: false
    // Keeps the window around while it fades out.
    property bool loaded: false
    property bool hovered: false
    property string screenName: ""
    // "", "saved" or "failed".
    property string saveState: ""

    function show(file: string) {
        if (!file.startsWith(dir) || file.includes(".."))
            return;
        // Normally the script has dismissed the last one already.
        if (path !== "" && path !== file)
            Quickshell.execDetached(["quickshell-screenshot", "discard", path]);
        path = file;
        saveState = "";
        hovered = false;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        shown = true;
        loaded = true;
        hideTimer.restart();
    }

    // Edit hands the file to satty, which removes it when it closes; every other way out does.
    function hide(handedOn: bool) {
        shown = false;
        if (!handedOn)
            Quickshell.execDetached(["quickshell-screenshot", "discard", path]);
    }

    function edit() {
        Quickshell.execDetached(["quickshell-screenshot", "edit", path]);
        hide(true);
    }

    function save() {
        if (saveProc.running || saveState === "saved")
            return;
        saveProc.savedPath = path;
        saveProc.command = ["quickshell-screenshot", "save", path];
        saveProc.running = true;
    }

    IpcHandler {
        target: "screenshot"

        // Not `show`: that is an `ipc` subcommand, which the call's argument parser takes it for.
        function taken(file: string): void {
            root.show(file);
        }

        function dismiss(): void {
            if (root.shown)
                root.hide(false);
        }
    }

    Process {
        id: saveProc

        // Whose save this is, in case a new capture arrives before it ends.
        property string savedPath: ""

        onExited: code => {
            if (savedPath !== root.path)
                return;
            root.saveState = code === 0 ? "saved" : "failed";
            // Long enough to read the confirmation; under the pointer, leaving starts it.
            if (!root.hovered)
                hideTimer.restart();
        }
    }

    // Paused while the pointer is on the card; it starts over on leaving.
    Timer {
        id: hideTimer
        interval: 6000
        running: root.shown && !root.hovered
        onTriggered: root.hide(false)
    }

    // Unloads once the fade-out has finished.
    Timer {
        running: !root.shown && root.loaded
        interval: Theme.durationExit + 30
        onTriggered: {
            root.loaded = false;
            root.path = "";
            root.hovered = false;
        }
    }

    LazyLoader {
        active: root.loaded

        PanelWindow {
            id: window

            // Room around the card for its shadow, which is also its distance from the corner.
            readonly property int shadowPadding: 24

            screen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]
            anchors {
                bottom: true
                right: true
            }
            margins.bottom: Theme.barAtTop ? 0 : Theme.barHeight
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: card.width + shadowPadding * 2
            implicitHeight: card.height + shadowPadding * 2
            color: "transparent"
            // Only the card takes input; the shadow around it is click-through.
            mask: Region {
                item: card
            }
            WlrLayershell.namespace: "screenshot"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Plate {
                id: card

                // Slides in from the screen edge like a notification, and back out to it.
                property real slide: 24

                width: 300
                height: column.implicitHeight + 24
                x: window.shadowPadding + slide
                y: window.shadowPadding
                opacity: 0

                // Fade in on creation too; later shows reuse the window if it hasn't unloaded yet.
                Component.onCompleted: {
                    opacity = Qt.binding(() => root.shown ? 1 : 0);
                    slide = Qt.binding(() => root.shown ? 0 : 24);
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.shown ? Theme.durationState : Theme.durationExit
                        easing.type: root.shown ? Theme.easing : Theme.easingExit
                    }
                }

                Behavior on slide {
                    NumberAnimation {
                        duration: root.shown ? Theme.durationState : Theme.durationExit
                        easing.type: root.shown ? Theme.easing : Theme.easingExit
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowOpacity: 0.35
                    shadowBlur: 1
                    shadowVerticalOffset: 8
                }

                HoverHandler {
                    onHoveredChanged: root.hovered = hovered
                }

                ColumnLayout {
                    id: column

                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // The clipboard has it already; this says so, then what Save did.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Icon {
                            Layout.preferredWidth: 20
                            text: root.saveState === "failed" ? Icons.alertCircle : Icons.check
                            color: root.saveState === "failed" ? Theme.alert : Theme.ok
                            font.pixelSize: 14
                        }

                        BarText {
                            Layout.fillWidth: true
                            text: root.saveState === "failed" ? "Couldn't save" : root.saveState === "saved" ? "Copied and saved" : "Copied to clipboard"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: Theme.radiusRow
                            color: closeArea.containsMouse ? Theme.rule : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durationState
                                    easing.type: Theme.easing
                                }
                            }

                            Icon {
                                anchors.centerIn: parent
                                text: Icons.close
                                color: closeArea.containsMouse ? Theme.text : Theme.muted
                                font.pixelSize: 13
                            }

                            // The glyph's square is 20px; the hit area reaches 24.
                            MouseArea {
                                id: closeArea

                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.hide(false)
                            }
                        }
                    }

                    // The picture in an inset well, fitted whole whatever the area's shape.
                    ClippingRectangle {
                        Layout.fillWidth: true
                        implicitHeight: 156
                        radius: Theme.radiusRow
                        color: Theme.inset
                        border.width: 1
                        border.color: Theme.rule

                        // A screenshot can hold anything on any window, so it stays off a shared
                        // screen like Pass's usernames (Privacy.onAir); the actions still work.
                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            // Not kept in the pixmap cache after the file is gone.
                            cache: false
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            source: root.path !== "" && !Privacy.onAir ? `file://${root.path}` : ""
                            sourceSize: Qt.size(width * 2, height * 2)
                            opacity: status === Image.Ready ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.durationState
                                    easing.type: Theme.easing
                                }
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            visible: Privacy.onAir
                            spacing: 8

                            Icon {
                                text: Icons.monitorShare
                                color: Theme.alert
                                font.pixelSize: 14
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: `${Privacy.screen.length === 0 && Privacy.recording ? "Recording" : "Sharing"} your screen: preview hidden`
                                color: Theme.text2
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        ActionButton {
                            glyph: Icons.pencil
                            label: "Edit"
                            onClicked: root.edit()
                        }

                        ActionButton {
                            readonly property bool saved: root.saveState === "saved"

                            glyph: saved ? Icons.check : Icons.contentSave
                            label: saved ? "Saved" : "Save"
                            // Saved once is saved; a failure can be tried again.
                            interactive: !saved
                            accent: saved ? Theme.ok : Theme.muted
                            onClicked: root.save()
                        }
                    }
                }
            }
        }
    }

    // Inset button with a glyph, as the notification popups' action buttons sit on their plate.
    component ActionButton: Rectangle {
        id: button

        property string glyph
        property string label
        property bool interactive: true
        property color accent: Theme.muted

        signal clicked

        Layout.fillWidth: true
        implicitHeight: 28
        radius: Theme.radiusRow
        color: interactive && area.containsMouse ? Theme.rule : Theme.inset

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            // An idle glyph steps up to text2 under the pointer.
            Icon {
                text: button.glyph
                color: button.interactive && area.containsMouse ? Theme.text2 : button.accent
                font.pixelSize: 14
            }

            BarText {
                text: button.label
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (button.interactive)
                button.clicked()
        }
    }
}
