import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// The control panel's Nix view: how last night's cache build went, what the cache holds, and
// where this computer stands against it (services/NixStatus.qml), with any failed systemd units
// (system and user) listed by name; a click copies the journalctl command for one. Off the home
// network only the failed units and the last section remain. Reads every minute while it is showing.
ColumnLayout {
    id: root

    readonly property string dashboard: "https://grafana.hera.ac/d/nix-cache"
    readonly property double nowSeconds: NixStatus.now / 1000
    readonly property string checkedText: NixStatus.fetchedAt === 0 ? "" : `Checked ${Qt.formatTime(new Date(NixStatus.fetchedAt), "HH:mm")}`

    // Icon colour, title and detail line of the header, from the nightly build's state.
    readonly property var head: {
        // Read from `data` alone: its derived properties update one after another.
        const build = NixStatus.data?.build;
        const lastFailed = build?.success === false;
        switch (NixStatus.stateOf(NixStatus.data)) {
        case "ok":
            return {
                tone: Theme.ok,
                title: "Last build succeeded",
                detail: [NixStatus.ago(build.last_run), build.duration === null ? "" : `took ${NixStatus.duration(build.duration)}`].filter(s => s !== "").join(", ")
            };
        case "failed":
            return {
                tone: Theme.alert,
                title: "Last build failed",
                detail: [NixStatus.ago(build.last_run), build.failed_phase ? `at the ${build.failed_phase} step` : ""].filter(s => s !== "").join(", ")
            };
        case "running":
            return {
                tone: lastFailed ? Theme.alert : Theme.text2,
                title: "Build running",
                detail: build.last_run === null ? "The first build is still in progress" : `Last one ${lastFailed ? `failed${build.failed_phase ? ` at the ${build.failed_phase} step` : ""}` : "succeeded"}, ${NixStatus.ago(build.last_run)}`
            };
        case "never":
            return {
                tone: Theme.muted,
                title: "No build yet",
                detail: build.next_run ? `Next nightly run ${nextRun(build.next_run)}` : "Waiting for the first run"
            };
        case "unreachable":
            return {
                tone: Theme.muted,
                title: "Cache unreachable",
                detail: "Showing this computer only"
            };
        default:
            return {
                tone: Theme.muted,
                title: "Checking…",
                detail: ""
            };
        }
    }

    // [{ title, lines: [{ key, value, tone?, fraction? }] }]; `fraction` draws a fill bar under the line.
    readonly property var sections: {
        const out = [];
        const d = NixStatus.data;
        if (d?.cache?.reachable ?? false) {
            out.push({
                title: "Last build",
                lines: buildLines(d)
            });
            out.push({
                title: "Cache",
                lines: cacheLines(d)
            });
        }
        if (d?.failed_units?.length)
            out.push({
                title: "Failed units",
                lines: unitLines(d.failed_units)
            });
        if (d?.system)
            out.push({
                title: "This computer",
                lines: systemLines(d)
            });
        return out;
    }

    property string copiedValue: ""

    signal linkOpened

    // "Fri 01:00, in 8 h" for an epoch in seconds ahead of the last read.
    function nextRun(epoch: real): string {
        const when = Qt.formatDateTime(new Date(epoch * 1000), "ddd HH:mm");
        return epoch > nowSeconds ? `${when}, in ${NixStatus.span(epoch - nowSeconds)}` : when;
    }

    // One line per failed unit, scope in the key; a click copies the command that reads its journal.
    function unitLines(units: var): var {
        return units.map(u => ({
                    key: u.scope === "user" ? "User" : "System",
                    value: u.name,
                    tone: Theme.alert,
                    // Quoted: escaped unit names (\x2d) lose their backslash unquoted.
                    copy: `journalctl ${u.scope === "user" ? "--user " : ""}-u '${u.name}'`
                }));
    }

    function count(n: var): string {
        return n.toLocaleString(Qt.locale(), "f", 0);
    }

    function buildLines(d: var): var {
        const b = d.build;
        const lines = [
            {
                key: "Last run",
                value: b.last_run === null ? "None yet" : [NixStatus.ago(b.last_run), b.duration === null ? "" : `took ${NixStatus.duration(b.duration)}`].filter(s => s !== "").join(", ")
            }
        ];
        if (b.next_run !== null)
            lines.push({
                key: "Next nightly",
                value: nextRun(b.next_run)
            });
        if (b.inputs_updated !== null)
            lines.push({
                key: "Inputs",
                value: b.inputs_updated === 0 ? "None updated" : `${b.inputs_updated} updated`
            });
        if (b.oldest_input !== null)
            lines.push({
                key: "Oldest input",
                value: `${b.oldest_input.name}, ${NixStatus.span(nowSeconds - b.oldest_input.modified)} old`
            });
        for (const target of b.targets)
            lines.push({
                key: target.name,
                value: target.success === true ? ["Built", NixStatus.bytes(target.closure_bytes)].filter(s => s !== "").join(" · ") : target.success === false ? "Failed" : "–",
                tone: target.success === false ? Theme.alert : undefined
            });
        return lines;
    }

    function cacheLines(d: var): var {
        const c = d.cache;
        const b = d.build;
        const lines = [];
        if (c.exporter_up === false)
            lines.push({
                key: "Exporter",
                value: "Not responding",
                tone: Theme.alert
            });
        if (c.stored_bytes !== null)
            lines.push({
                key: "Stored",
                value: c.objects === 0 ? "Empty" : `${NixStatus.bytes(c.stored_bytes)}${c.nar_bytes ? `, ${NixStatus.bytes(c.nar_bytes)} unpacked` : ""}`
            });
        if (c.objects !== null)
            lines.push({
                key: "Paths",
                value: `${count(c.objects)}${c.accessed_24h === null ? "" : `, ${count(c.accessed_24h)} fetched in 24 h`}`
            });
        if (c.objects !== null)
            lines.push({
                key: "Last push",
                value: c.last_push === null ? "Nothing yet" : NixStatus.ago(c.last_push)
            });
        if (b.store_size_bytes && b.store_used_bytes !== null) {
            const fraction = Math.min(1, b.store_used_bytes / b.store_size_bytes);
            const high = fraction >= 0.85;
            lines.push({
                key: "Builder store",
                value: `${Math.round(fraction * 100)}% of ${NixStatus.bytes(b.store_size_bytes)}${high ? ", nearly full" : ""}`,
                tone: high ? Theme.caution : undefined,
                fraction: fraction
            });
        }
        return lines;
    }

    function systemLines(d: var): var {
        const s = d.system;
        const lines = [];
        if (s.version)
            lines.push({
                key: "NixOS",
                value: s.version
            });
        if (s.generation !== null)
            lines.push({
                key: "Generation",
                value: [`${s.generation}`, NixStatus.ago(s.generation_time)].filter(v => v !== "").join(", ")
            });
        if (d.upstream?.update_available !== null && d.upstream?.update_available !== undefined)
            lines.push({
                key: "Updates",
                value: d.upstream.update_available ? "main has a newer lock" : "Matches main's lock"
            });
        if (d.failed_units)
            lines.push({
                key: "Units",
                value: d.failed_units.length === 0 ? "None failed" : `${d.failed_units.length} failed`,
                tone: d.failed_units.length === 0 ? undefined : Theme.alert
            });
        lines.push({
            key: "Reboot",
            value: s.reboot_pending ? "Pending, new kernel or modules" : "Not needed"
        });
        if (s.cached !== null)
            lines.push({
                key: "Cache",
                value: s.cached ? "This system is in the cache" : "This system isn't in the cache yet"
            });
        return lines;
    }

    spacing: 4

    function copy(command: string) {
        Quickshell.clipboardText = command;
        copiedValue = command;
        copiedReset.restart();
    }

    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: root.copiedValue = ""
    }

    Component.onCompleted: NixStatus.acquire()
    // The panel's view Loader destroys this when switching back to the main view.
    Component.onDestruction: NixStatus.release()

    // State at a glance.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.bottomMargin: 6
        spacing: 12

        Icon {
            text: Icons.nixos
            color: root.head.tone
            font.pixelSize: 22
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            BarText {
                Layout.fillWidth: true
                text: root.head.title
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.head.detail
                color: Theme.text2
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    Repeater {
        model: root.sections

        Rectangle {
            id: section

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: sectionColumn.implicitHeight + 12
            radius: Theme.radiusInset
            color: Theme.inset

            ColumnLayout {
                id: sectionColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

                BarText {
                    Layout.leftMargin: 6
                    Layout.bottomMargin: 2
                    text: section.modelData.title
                    color: Theme.text2
                    font.pixelSize: 11
                }

                Repeater {
                    model: section.modelData.lines

                    Rectangle {
                        id: line

                        required property var modelData
                        readonly property bool copyable: modelData.copy !== undefined
                        readonly property bool copied: copyable && root.copiedValue === modelData.copy

                        Layout.fillWidth: true
                        implicitHeight: lineColumn.implicitHeight
                        radius: Theme.radiusRow
                        color: copyable && lineArea.containsMouse ? Theme.rule : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationState
                                easing.type: Theme.easing
                            }
                        }

                        ColumnLayout {
                            id: lineColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                Layout.bottomMargin: line.modelData.fraction === undefined ? 4 : 3
                                spacing: 8

                                BarText {
                                    Layout.preferredWidth: 88
                                    Layout.alignment: Qt.AlignTop
                                    text: line.modelData.key
                                    color: Theme.text2
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                BarText {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    text: line.copied ? "Copied journal command" : line.modelData.value
                                    color: line.copied ? Theme.ok : line.modelData.tone ?? Theme.text
                                    font.pixelSize: 12
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                            }

                            // A fill bar, on plate so it shows on the inset section.
                            Rectangle {
                                visible: line.modelData.fraction !== undefined
                                Layout.fillWidth: true
                                Layout.bottomMargin: 4
                                implicitHeight: 4
                                radius: 2
                                color: Theme.plate

                                Rectangle {
                                    width: parent.width * (line.modelData.fraction ?? 0)
                                    height: parent.height
                                    radius: 2
                                    color: line.modelData.tone ?? Theme.fill
                                }
                            }
                        }

                        MouseArea {
                            id: lineArea
                            anchors.fill: parent
                            enabled: line.copyable
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copy(line.modelData.copy)
                        }
                    }
                }
            }
        }
    }

    ListRow {
        Layout.fillWidth: true
        Layout.topMargin: 4
        icon: Icons.openInNew
        label: "Open dashboard"
        sublabel: "Grafana"
        onClicked: {
            Quickshell.execDetached(["xdg-open", root.dashboard]);
            root.linkOpened();
        }
    }

    BarText {
        visible: text !== ""
        Layout.leftMargin: 12
        text: NixStatus.failed ? `${root.checkedText === "" ? "" : `${root.checkedText}. `}Couldn't refresh` : root.checkedText
        color: Theme.text2
        font.pixelSize: 11
    }
}
