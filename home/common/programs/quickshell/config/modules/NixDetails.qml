import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// The control panel's Nix view: the lock updates waiting to land (BOT Cecil's pull requests, one
// per flake input, with how their checks go and how long a broken one has been failing), how
// main's builds into the cache are going, what the cache holds, and where this computer stands
// against it (services/NixStatus.qml), with any failed systemd units (system and user) listed by
// name; a click copies the journalctl command for one, or opens an update's pull request. Off the
// home network only the failed units and the last section remain. Reads every minute while it is
// showing.
ColumnLayout {
    id: root

    readonly property string dashboard: "https://grafana.hera.ac/d/nix-cache"
    readonly property double nowSeconds: NixStatus.now / 1000
    readonly property string checkedText: NixStatus.fetchedAt === 0 ? "" : `Checked ${Qt.formatTime(new Date(NixStatus.fetchedAt), "HH:mm")}`

    // Icon colour, title and detail line of the header, from the first thing that needs attention.
    readonly property var head: {
        // Read from `data` alone: its derived properties update one after another.
        const build = NixStatus.data?.build;
        const updates = NixStatus.data?.updates ?? [];
        switch (NixStatus.stateOf(NixStatus.data)) {
        case "ok":
            return {
                tone: Theme.ok,
                title: "Up to date",
                detail: [`main built ${NixStatus.ago(build.main?.finished ?? build.last_run)}`, "no lock updates open"].join(", ")
            };
        case "failed":
            {
                const failedTargets = build.targets.filter(t => t.success === false).map(t => t.name);
                return {
                    tone: Theme.alert,
                    title: "main isn't building",
                    detail: [build.main.failing_since ? `Failing for ${NixStatus.span(nowSeconds - build.main.failing_since)}` : "Failing", failedTargets.length ? failedTargets.join(" and ") : ""].filter(s => s !== "").join(": ")
                };
            }
        case "update-failing":
            {
                const failing = NixStatus.failingUpdates(NixStatus.data);
                const since = NixStatus.updateFailingSince(failing[0]);
                const span = since === null ? "" : `, for ${NixStatus.span(nowSeconds - since)}`;
                return {
                    tone: Theme.alert,
                    title: failing.length === 1 ? `${failing[0].input} update failing` : `${failing.length} lock updates failing`,
                    detail: failing.length === 1 ? `#${failing[0].number}${span}: ${NixStatus.names(NixStatus.failingChecks(failing[0]))}` : `${NixStatus.inputs(failing)}${span}`
                };
            }
        case "update-pending":
            {
                if (updates.length > 1)
                    return {
                        tone: Theme.text2,
                        title: `${updates.length} lock updates pending`,
                        detail: NixStatus.inputs(updates)
                    };
                const update = updates[0];
                const pending = NixStatus.pendingChecks(update);
                return {
                    tone: Theme.text2,
                    title: `${update.input} update pending`,
                    detail: pending.length === 0 ? `#${update.number}, every check passed, merging` : `#${update.number}, waiting on ${NixStatus.names(pending)}`
                };
            }
        case "running":
            return {
                tone: Theme.text2,
                title: "Build running",
                detail: build.last_run === null ? "The first build is still in progress" : `Last one ${build.success === false ? "failed" : "succeeded"}, ${NixStatus.ago(build.last_run)}`
            };
        case "never":
            return {
                tone: Theme.muted,
                title: "No build yet",
                detail: "Waiting for the first run"
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

    // [{ title, lines: [{ key, value, tone?, fraction?, copy?, url? }] }]; `fraction` draws a fill
    // bar under the line, `copy` copies on click, `url` opens on click.
    readonly property var sections: {
        const out = [];
        const d = NixStatus.data;
        if ((d?.updates ?? []).length > 0)
            out.push({
                title: "Lock updates",
                lines: d.updates.map(updateLine)
            });
        if (d?.cache?.reachable ?? false) {
            out.push({
                title: "Builds",
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

    // One line an update, by input: how its checks go, or how long it has failed; a click opens
    // its pull request.
    function updateLine(u: var): var {
        const failing = NixStatus.failingChecks(u);
        const pending = NixStatus.pendingChecks(u);
        let value;
        if (u.checks === null) {
            value = `#${u.number}, opened ${NixStatus.ago(u.opened_at)}`;
        } else if (failing.length > 0) {
            const since = NixStatus.updateFailingSince(u);
            value = `#${u.number}, ${NixStatus.names(failing)} failing${since === null ? "" : ` for ${NixStatus.span(nowSeconds - since)}`}`;
        } else if (pending.length > 0) {
            value = `#${u.number}, waiting on ${NixStatus.names(pending)}`;
        } else {
            value = u.auto_merge ? `#${u.number}, passed, merging` : `#${u.number}, passed; merge it on GitHub`;
        }
        return {
            key: u.input,
            value: value,
            url: u.url,
            tone: failing.length > 0 ? Theme.alert : pending.length > 0 ? Theme.text2 : undefined
        };
    }

    function buildLines(d: var): var {
        const b = d.build;
        const lines = [
            {
                key: "Last run",
                value: b.last_run === null ? "None yet" : [NixStatus.ago(b.last_run), b.duration === null ? "" : `took ${NixStatus.duration(b.duration)}`].filter(s => s !== "").join(", ")
            }
        ];
        if (b.main?.success !== null && b.main?.success !== undefined)
            lines.push({
                key: "main",
                value: b.main.success ? `Built and cached ${NixStatus.ago(b.main.finished)}` : b.main.failing_since ? `Failing for ${NixStatus.span(nowSeconds - b.main.failing_since)}` : "Failing",
                tone: b.main.success ? undefined : Theme.alert
            });
        for (const target of b.targets)
            lines.push({
                key: target.name,
                value: target.success === true ? ["Built", NixStatus.bytes(target.closure_bytes)].filter(s => s !== "").join(" · ") : target.success === false ? "Failed" : "–",
                tone: target.success === false ? Theme.alert : undefined
            });
        if (b.oldest_input !== null)
            lines.push({
                key: "Oldest input",
                value: `${b.oldest_input.name}, ${NixStatus.span(nowSeconds - b.oldest_input.modified)} old`
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
                value: d.upstream.update_available ? "main has a newer lock, switch to it" : "Matches main's lock"
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
                        readonly property bool linked: modelData.url !== undefined
                        readonly property bool copied: copyable && root.copiedValue === modelData.copy

                        Layout.fillWidth: true
                        implicitHeight: lineColumn.implicitHeight
                        radius: Theme.radiusRow
                        color: (copyable || linked) && lineArea.containsMouse ? Theme.rule : "transparent"

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
                            enabled: line.copyable || line.linked
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (line.linked) {
                                    Quickshell.execDetached(["xdg-open", line.modelData.url]);
                                    root.linkOpened();
                                } else {
                                    root.copy(line.modelData.copy);
                                }
                            }
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
