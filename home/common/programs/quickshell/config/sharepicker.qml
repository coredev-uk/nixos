//@ pragma IconTheme Papirus-Dark

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.share
import qs.widgets

// Screen-share picker replacing hyprland-share-picker; run by xdph (quickshell-share-picker wrapper).
// A card shows a still of every screen/window; click shares one, the region tile takes a drag.
// The choice goes to $QS_SHARE_OUT as xdph's selection ("r/screen:DP-1", "/window:<handle>",
// "/region:DP-1@x,y,w,h"); nothing written = cancel. Run by hand (qs -p sharepicker.qml) it lists
// every window and logs the choice.
ShellRoot {
    id: root

    readonly property string outPath: Quickshell.env("QS_SHARE_OUT") ?? ""
    // Restore token: lets the app re-share without asking.
    property bool allowToken: Quickshell.env("QS_SHARE_ALLOW_TOKEN") === "1"
    // Set by the first Tab/arrow key; the focus ring stays off until then.
    property bool keyboard: false
    // "pick" | "region"
    property string mode: "pick"

    // xdph's windows: "handle[HC>]class[HT>]title[HE>]address[HA>]"; address is Hyprland's, decimal (0 if unmapped).
    readonly property var offered: {
        const list = Quickshell.env("XDPH_WINDOW_SHARING_LIST");
        if (list === null || list === undefined)
            return null;
        return list.split("[HA>]").map(e => e.match(/^([\s\S]*?)\[HC>\]([\s\S]*?)\[HT>\]([\s\S]*?)\[HE>\]([\s\S]*)$/)).filter(m => m !== null).map(m => ({
                    handle: m[1],
                    cls: m[2],
                    title: m[3],
                    address: Number(m[4])
                }));
    }

    // Offered windows (all of them when run by hand) with Hyprland toplevel and workspace, in workspace order.
    readonly property var windows: {
        const tops = Hyprland.toplevels.values;
        const classOf = t => t.lastIpcObject?.class ?? "";
        const entries = offered ?? tops.map(t => ({
                    handle: t.address,
                    cls: classOf(t),
                    title: t.title,
                    address: parseInt(t.address, 16)
                }));
        const order = w => {
            const id = w.toplevel?.workspace?.id ?? 0;
            return id > 0 ? id : 1e6 - id;
        };
        return entries.map(e => ({
                    handle: e.handle,
                    cls: e.cls,
                    title: e.title,
                    toplevel: tops.find(t => e.address !== 0 && parseInt(t.address, 16) === e.address) ?? tops.find(t => t.title === e.title && classOf(t) === e.cls) ?? null
                })).sort((a, b) => order(a) - order(b));
    }

    function share(selection: string) {
        const line = `${allowToken ? "r" : ""}/${selection}`;
        if (outPath === "") {
            console.info(`selection: ${line}`);
            Qt.quit();
            return;
        }
        out.setText(line);
    }

    function cancel() {
        Qt.quit();
    }

    function where(toplevel: var): string {
        const ws = toplevel?.workspace;
        if (!ws)
            return "";
        return ws.id > 0 ? `workspace ${ws.name}` : (ws.name.replace(/^special:?/, "") || "special") + " scratchpad";
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    FileView {
        id: out

        path: root.outPath
        blockWrites: true
        onSaved: Qt.quit()
        onSaveFailed: Qt.quit()
    }

    PanelWindow {
        id: picker

        // Card shows once every still is taken, so stills don't capture the picker.
        property bool shown: false
        readonly property int columns: 3
        readonly property int gap: 16
        // Stills take this screen's shape (tiled windows share it), clamped 16:10 to 21:9.
        readonly property real aspect: Math.max(16 / 10, Math.min(21 / 9, width / Math.max(1, height)))
        readonly property color dim: Theme.tint(Theme.ground, 0.6)

        function reveal() {
            if (shown)
                return;
            shown = true;
            appear.restart();
            nav.forceActiveFocus();
            firstTile()?.forceActiveFocus();
        }

        function checkCaptured() {
            for (let i = 0; i < screenTiles.count; i++)
                if (!screenTiles.itemAt(i)?.captured)
                    return;
            reveal();
        }

        function firstTile(): var {
            return screenTiles.count > 0 ? screenTiles.itemAt(0) : null;
        }

        function tiles(): var {
            const list = [];
            for (let i = 0; i < screenTiles.count; i++)
                list.push(screenTiles.itemAt(i));
            list.push(regionTile);
            for (let i = 0; i < windowTiles.count; i++)
                list.push(windowTiles.itemAt(i));
            return list.filter(t => t !== null);
        }

        // Left/right step through the list; up/down take the nearest tile in the next row.
        function move(dx: int, dy: int) {
            const list = tiles();
            const from = list.findIndex(t => t.activeFocus);
            if (from < 0) {
                list[0]?.forceActiveFocus();
                return;
            }
            let target = null;
            if (dy === 0) {
                target = list[from + dx] ?? null;
            } else {
                const here = list[from].mapToItem(sections, 0, 0);
                let best = Infinity;
                for (const t of list) {
                    const at = t.mapToItem(sections, 0, 0);
                    const rows = (at.y - here.y) * dy;
                    if (rows <= 1)
                        continue;
                    const score = rows * 10000 + Math.abs(at.x - here.x);
                    if (score < best) {
                        best = score;
                        target = t;
                    }
                }
            }
            target?.forceActiveFocus();
        }

        function ensureVisible(tile: var) {
            const top = tile.mapToItem(flick.contentItem, 0, 0).y;
            const bottom = top + tile.height;
            if (top < flick.contentY)
                flick.contentY = Math.max(0, top);
            else if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(flick.contentHeight - flick.height, bottom - flick.height);
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-share-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        // A region drag takes the keyboard and draws its own dim; this window stays mapped so stills aren't retaken.
        WlrLayershell.keyboardFocus: root.mode === "pick" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: shown && root.mode === "pick" ? dim : "transparent"

        Connections {
            target: root

            function onModeChanged() {
                if (root.mode === "pick") {
                    nav.forceActiveFocus();
                    regionTile.forceActiveFocus();
                }
            }
        }

        // A screen that never delivers a frame must not block the picker.
        Timer {
            running: !picker.shown
            interval: 500
            onTriggered: picker.reveal()
        }

        ParallelAnimation {
            id: appear

            ColorAnimation {
                target: picker
                property: "color"
                from: "transparent"
                to: picker.dim
                duration: Theme.durationState
                easing.type: Theme.easing
            }
            NumberAnimation {
                target: stage
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.durationState
                easing.type: Theme.easing
            }
            NumberAnimation {
                target: nudge
                property: "y"
                from: 8
                to: 0
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: picker.shown && root.mode === "pick"
            onClicked: root.cancel()
        }

        Item {
            id: stage

            anchors.centerIn: parent
            width: Math.min(parent.width - 160, 1280)
            height: Math.min(body.implicitHeight + 40, parent.height - 120)
            opacity: 0
            visible: root.mode === "pick"

            transform: Translate {
                id: nudge
            }

            // Float: the shadow sits under the card, so live stills aren't rendered into a layer.
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusPlate
                color: Theme.plate
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowOpacity: 0.35
                    shadowBlur: 1
                    shadowVerticalOffset: 8
                }
            }

            Plate {
                id: card

                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                }

                Item {
                    id: nav

                    anchors.fill: parent
                    anchors.margins: 20

                    // Tab is walked by Qt and reported by tiles; arrows and Escape bubble up here.
                    Keys.onPressed: e => {
                        const step = {
                            [Qt.Key_Left]: [-1, 0],
                            [Qt.Key_Right]: [1, 0],
                            [Qt.Key_Up]: [0, -1],
                            [Qt.Key_Down]: [0, 1]
                        }[e.key];
                        if (!step)
                            return;
                        e.accepted = true;
                        root.keyboard = true;
                        picker.move(step[0], step[1]);
                    }
                    Keys.onEscapePressed: root.cancel()

                    ColumnLayout {
                        id: body

                        anchors.fill: parent
                        spacing: 0

                        RowLayout {
                            spacing: 12
                            Layout.fillWidth: true

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: Theme.radiusRow
                                color: Theme.inset

                                Icon {
                                    anchors.centerIn: parent
                                    text: Icons.monitorShare
                                    // Badge for the dialog, not a state: gilt is reserved for here/on.
                                    color: Theme.text2
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                BarText {
                                    text: "Choose what to share"
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                BarText {
                                    text: "Click a screen, a window or a region to start sharing it."
                                    color: Theme.text2
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Flickable {
                            id: flick

                            readonly property real tileWidth: Math.floor((width - picker.gap * (picker.columns - 1)) / picker.columns)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 20
                            Layout.preferredHeight: sections.implicitHeight
                            Layout.minimumHeight: Math.min(sections.implicitHeight, 160)
                            contentHeight: sections.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: sections

                                width: flick.width
                                spacing: 0

                                SectionLabel {
                                    text: "Screens"
                                    Layout.leftMargin: 0
                                }

                                Grid {
                                    columns: picker.columns
                                    columnSpacing: picker.gap
                                    rowSpacing: 16
                                    Layout.topMargin: 8

                                    Repeater {
                                        id: screenTiles

                                        model: Quickshell.screens

                                        ShareTile {
                                            id: screenTile

                                            required property var modelData

                                            width: flick.tileWidth
                                            aspect: picker.aspect
                                            source: modelData
                                            glyph: Icons.monitor
                                            title: modelData.name
                                            detail: `${modelData.width} × ${modelData.height}`
                                            keyboard: root.keyboard
                                            onKeyboardUsed: root.keyboard = true
                                            onReached: picker.ensureVisible(screenTile)
                                            onCapturedChanged: picker.checkCaptured()
                                            onChosen: root.share(`screen:${modelData.name}`)
                                        }
                                    }

                                    ShareTile {
                                        id: regionTile

                                        width: flick.tileWidth
                                        aspect: picker.aspect
                                        dashed: true
                                        title: "Region"
                                        detail: "Drag out part of a screen"
                                        keyboard: root.keyboard
                                        onKeyboardUsed: root.keyboard = true
                                        onReached: picker.ensureVisible(regionTile)
                                        onChosen: root.mode = "region"
                                    }
                                }

                                SectionLabel {
                                    text: "Windows"
                                    Layout.leftMargin: 0
                                    Layout.topMargin: 24
                                }

                                BarText {
                                    visible: root.windows.length === 0
                                    text: "No windows are open."
                                    color: Theme.text2
                                    font.pixelSize: 12
                                    Layout.topMargin: 8
                                }

                                Grid {
                                    visible: root.windows.length > 0
                                    columns: picker.columns
                                    columnSpacing: picker.gap
                                    rowSpacing: 16
                                    Layout.topMargin: 8

                                    Repeater {
                                        id: windowTiles

                                        model: root.windows

                                        ShareTile {
                                            id: windowTile

                                            required property var modelData
                                            readonly property var entry: DesktopEntries.applications.values.length > 0 ? DesktopEntries.heuristicLookup(modelData.cls) : null

                                            width: flick.tileWidth
                                            aspect: picker.aspect
                                            source: modelData.toplevel?.wayland ?? null
                                            icon: entry?.icon ? Quickshell.iconPath(entry.icon, true) : ""
                                            title: modelData.title || entry?.name || modelData.cls
                                            detail: [entry?.name || modelData.cls, root.where(modelData.toplevel)].filter(s => s !== "").join(" · ")
                                            keyboard: root.keyboard
                                            onKeyboardUsed: root.keyboard = true
                                            onReached: picker.ensureVisible(windowTile)
                                            onChosen: root.share(`window:${modelData.handle}`)
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 10
                            Layout.fillWidth: true
                            Layout.topMargin: 16

                            MouseArea {
                                id: tokenRow

                                readonly property bool lit: activeFocus && root.keyboard

                                Layout.fillWidth: true
                                implicitHeight: 32
                                hoverEnabled: true
                                activeFocusOnTab: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.allowToken = !root.allowToken
                                onActiveFocusChanged: {
                                    if (activeFocus)
                                        picker.ensureVisible(tokenRow);
                                }
                                Keys.onPressed: e => {
                                    if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab)
                                        root.keyboard = true;
                                    if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
                                        return;
                                    e.accepted = true;
                                    if (!e.isAutoRepeat)
                                        root.allowToken = !root.allowToken;
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusRow
                                    color: tokenRow.containsMouse ? Theme.hover : "transparent"
                                    border.width: tokenRow.lit ? 1 : 0
                                    border.color: Theme.gilt
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    spacing: 10

                                    Icon {
                                        text: root.allowToken ? Icons.checkboxOn : Icons.checkboxOff
                                        color: root.allowToken ? Theme.gilt : Theme.muted
                                    }

                                    BarText {
                                        Layout.fillWidth: true
                                        text: "Let the app share this again without asking"
                                        font.pixelSize: 12
                                    }
                                }

                            }

                            DialogButton {
                                label: "Cancel"
                                onClicked: root.cancel()
                            }
                        }
                    }
                }

                Rectangle {
                    visible: flick.contentHeight > flick.height
                    x: card.width - 10
                    y: nav.y + flick.y + flick.visibleArea.yPosition * flick.height
                    width: 4
                    height: flick.visibleArea.heightRatio * flick.height
                    radius: 2
                    color: Theme.rule
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        RegionSelect {
            visible: root.mode === "region"
            onChosen: (output, region) => root.share(`region:${output}@${region}`)
            onBack: root.mode = "pick"
        }
    }
}
