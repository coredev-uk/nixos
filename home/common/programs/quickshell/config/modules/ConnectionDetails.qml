import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.common
import qs.widgets

// Addressing and hardware of one network device. Quickshell.Networking has no IP configuration,
// so it is read from `nmcli device show`, again whenever the device changes state.
// Clicking a value copies it.
ColumnLayout {
    id: root

    // A NetworkDevice; WiredDevice adds hasLink and linkSpeed. Null when there is none.
    required property var device
    // nmcli fields with the [n] index dropped, so IP4.DNS[1], IP4.DNS[2] … collect into one list.
    property var fields: ({})
    property string copiedValue: ""

    readonly property bool hasLink: device?.hasLink ?? device?.connected ?? false
    readonly property string speed: {
        const mbps = device?.linkSpeed ?? 0;
        return mbps <= 0 ? "" : mbps >= 1000 ? `${mbps / 1000} Gb/s` : `${mbps} Mb/s`;
    }
    readonly property string internet: {
        switch (/\((\w+)\)/.exec(first("GENERAL.IP4-CONNECTIVITY"))?.[1]) {
        case "full":
            return "Internet";
        case "limited":
            return "Local network only";
        case "portal":
            return "Sign-in required";
        case "none":
            return "No internet";
        default:
            return "";
        }
    }
    readonly property string status: {
        if (!device)
            return "No device";
        if (device.connected)
            return ["Connected", speed, internet].filter(s => s !== "").join(" · ");
        if (!hasLink)
            return "Cable unplugged";
        switch (device.state) {
        case ConnectionState.Connecting:
            return "Connecting…";
        case ConnectionState.Disconnecting:
            return "Disconnecting…";
        default:
            return "Not connected";
        }
    }
    readonly property var sections: [
        {
            title: "IPv4",
            rows: [["Address", all("IP4.ADDRESS")], ["Gateway", all("IP4.GATEWAY")], ["DNS", all("IP4.DNS")], ["Domain", all("IP4.DOMAIN")]]
        },
        {
            title: "IPv6",
            rows: [["Address", all("IP6.ADDRESS").filter(a => !a.startsWith("fe80:"))], ["Gateway", all("IP6.GATEWAY")], ["DNS", all("IP6.DNS")]]
        },
        {
            title: "Hardware",
            rows: [["Interface", [device?.name ?? ""]], ["Adapter", [adapter()]], ["MAC", [device?.address ?? ""]], ["Speed", [speed]], ["MTU", [first("GENERAL.MTU")]]]
        }
    ].map(section => ({
                title: section.title,
                lines: linesOf(section.rows)
            })).filter(section => section.lines.length > 0)

    // One line per value; the key is only printed on a key's first line.
    function linesOf(rows: var): var {
        const lines = [];
        for (const [key, values] of rows)
            values.filter(v => v !== "").forEach((value, i) => lines.push({
                    key: i === 0 ? key : "",
                    value
                }));
        return lines;
    }

    function all(key: string): var {
        return fields[key] ?? [];
    }

    function first(key: string): string {
        return all(key)[0] ?? "";
    }

    function adapter(): string {
        const vendor = first("GENERAL.VENDOR").split(" ")[0];
        const product = first("GENERAL.PRODUCT");
        return product === "" ? "" : vendor === "" ? product : `${vendor} ${product}`;
    }

    function refresh() {
        if (!device || reader.running)
            return;
        reader.command = ["nmcli", "--terse", "--escape", "no", "--fields", "GENERAL,IP4,IP6", "device", "show", device.name];
        reader.running = true;
    }

    function copy(value: string) {
        Quickshell.clipboardText = value;
        copiedValue = value;
        copiedReset.restart();
    }

    spacing: 4
    Component.onCompleted: refresh()

    // A state change lands before NetworkManager has the new addresses; read shortly after.
    Connections {
        target: root.device
        function onStateChanged() {
            refreshDelay.restart();
        }
    }

    Timer {
        id: refreshDelay
        interval: 750
        onTriggered: root.refresh()
    }

    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: root.copiedValue = ""
    }

    Process {
        id: reader
        stdout: StdioCollector {
            id: readerOut
            onStreamFinished: {
                const fields = {};
                for (const line of readerOut.text.split("\n")) {
                    const colon = line.indexOf(":");
                    const value = line.slice(colon + 1).trim();
                    if (colon < 0 || value === "" || value === "--")
                        continue;
                    const key = line.slice(0, colon).replace(/\[\d+\]$/, "");
                    fields[key] = (fields[key] ?? []).concat(value);
                }
                root.fields = fields;
            }
        }
    }

    // Connection name and state.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.bottomMargin: 6
        spacing: 12

        Icon {
            text: root.device?.connected ? Icons.ethernet : Icons.disconnected
            color: root.device?.connected ? Theme.gilt : Theme.muted
            font.pixelSize: 22
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            BarText {
                Layout.fillWidth: true
                text: root.device?.connected ? (root.first("GENERAL.CONNECTION") || root.device.name) : "Not connected"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            BarText {
                Layout.fillWidth: true
                text: root.status
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
                        readonly property bool copied: root.copiedValue === modelData.value

                        Layout.fillWidth: true
                        implicitHeight: lineRow.implicitHeight + 8
                        radius: Theme.radiusRow
                        color: lineArea.containsMouse ? Theme.rule : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationState
                                easing.type: Theme.easing
                            }
                        }

                        RowLayout {
                            id: lineRow
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            BarText {
                                Layout.preferredWidth: 64
                                Layout.alignment: Qt.AlignTop
                                text: line.modelData.key
                                color: Theme.text2
                                font.pixelSize: 12
                            }

                            BarText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                // Long IPv6 addresses break between groups, not inside one.
                                text: line.copied ? "Copied" : line.modelData.value.replace(/:/g, ":\u200B")
                                color: line.copied ? Theme.ok : Theme.text
                                font.pixelSize: 12
                                font.features: {
                                    "tnum": 1
                                }
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }

                        MouseArea {
                            id: lineArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copy(line.modelData.value)
                        }
                    }
                }
            }
        }
    }

    ListRow {
        visible: root.device !== null
        Layout.fillWidth: true
        Layout.topMargin: 4
        icon: root.device?.connected ? Icons.disconnected : Icons.ethernet
        label: root.device?.connected ? "Disconnect" : root.hasLink ? "Connect" : "Plug in a cable to connect"
        active: !root.device?.connected && root.hasLink
        enabled: root.device?.connected || root.hasLink
        onClicked: Quickshell.execDetached(["nmcli", "device", root.device.connected ? "disconnect" : "connect", root.device.name])
    }
}
