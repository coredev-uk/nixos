import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs.common
import qs.services
import qs.widgets

// The control panel behind the network glyph: a rail of sections down its left edge (Sound,
// Display, Network, Devices, Nix, Claude) and the chosen one beside it, one at a time. The plate
// keeps one height whichever section shows, so moving between them never moves an edge; a long
// section scrolls inside it. What's playing sits under every section (MediaPanel). A rail glyph
// that reports something (the network down, a Nix failure, Claude's limit reached) takes that
// state's colour. The chosen section is marked by one gilt tint that glides along the rail to the
// tile picked, and the section arrives from the side it lies on: from below when it sits lower on
// the rail than the one it replaces. Opening, the contents settle the last 8px as Hyprland fades
// the popup in.
BarPopup {
    id: root

    enum Section {
        Sound,
        Display,
        Network,
        Devices,
        System,
        Claude
    }

    // Network's sub-views.
    enum View {
        Main,
        Wifi,
        Ethernet,
        Vpn
    }

    // Kept while the panel is reopened; a network sub-view goes back to its list on opening.
    property int section: ControlPanel.Section.Sound
    property int view: ControlPanel.View.Main
    // The section shown before the current one, for the side the next arrives from.
    property int lastSection: section
    // The section's own height, the same for all of them.
    readonly property int pageHeight: 380
    readonly property var wifiDevice: NetworkStatus.wifiDevice
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // Secured network waiting for a password, and the last connection error.
    property WifiNetwork passwordNetwork: null
    property string wifiError: ""

    // Opens on a section (the low-battery glyph opens Devices).
    function show(section: int) {
        root.section = section;
        if (!visible)
            toggle();
    }

    // NetworkManager's reasons, in plain words.
    function failReason(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "it needs the password";
        case ConnectionFailReason.WifiClientFailed:
            return "the password was rejected";
        case ConnectionFailReason.WifiAuthTimeout:
            return "the network took too long to answer";
        case ConnectionFailReason.WifiClientDisconnected:
            return "the network dropped the connection";
        case ConnectionFailReason.WifiNetworkLost:
            return "the network went out of range";
        default:
            return "";
        }
    }

    function vpnStatus(): string {
        if (Vpn.connecting)
            return `Connecting to ${Vpn.target === "" ? "the fastest server" : Vpn.countryName(Vpn.target)}…`;
        if (Vpn.disconnecting)
            return "Disconnecting…";
        if (!Vpn.connected)
            return "Disconnected";
        if (Vpn.country === "")
            return Vpn.server === "" ? "Connected" : `Connected - ${Vpn.server}`;
        return `Connected - ${Vpn.countryName(Vpn.country)}${Vpn.server === "" ? "" : ` (${Vpn.server})`}`;
    }

    function castScreen() {
        Quickshell.execDetached(["gnome-network-displays"]);
        root.visible = false;
    }

    // Bluetooth devices by what they are, from BlueZ's icon name; the Bluetooth glyph otherwise.
    function deviceGlyph(device: BluetoothDevice): string {
        const icon = device.icon ?? "";
        if (icon.includes("headset") || icon.includes("headphone"))
            return Icons.headphones;
        if (icon.includes("mouse"))
            return Icons.mouse;
        if (icon.includes("keyboard"))
            return Icons.keyboard;
        if (icon.includes("audio") || icon.includes("speaker"))
            return Icons.speaker;
        return device.connected ? Icons.bluetoothConnected : Icons.bluetooth;
    }

    function updateScanner() {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible && section === ControlPanel.Section.Network && view === ControlPanel.View.Wifi;
    }

    function connectWifi(network: WifiNetwork) {
        if (network.connected)
            return;
        wifiError = "";
        if (!network.known && network.security !== WifiSecurityType.Open)
            passwordNetwork = network;
        else
            network.connect();
    }

    function wifiFailed(network: WifiNetwork, reason: int) {
        const why = failReason(reason);
        wifiError = why === "" ? `Couldn't connect to ${network.name}.` : `Couldn't connect to ${network.name}: ${why}.`;
        // Missing or rejected secrets: ask for the password again.
        if (network.security !== WifiSecurityType.Open && (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiClientFailed))
            passwordNetwork = network;
    }

    onOpening: {
        view = ControlPanel.View.Main;
        // The popup itself fades in on open; only switches while open move the section.
        pageFade.complete();
        pageIn.complete();
        lastSection = section;
        settle.restart();
        // Both can be changed outside the shell (monitor buttons, hyprsunset's schedule).
        Brightness.refresh();
        NightLight.refresh();
        AirPlay.refresh();
        NixStatus.refresh(20000);
        if (section === ControlPanel.Section.Claude)
            ClaudeUsage.refresh(false);
    }
    onVisibleChanged: updateScanner()
    onSectionChanged: {
        view = ControlPanel.View.Main;
        updateScanner();
        pageIn.from = section > lastSection ? 12 : -12;
        pageIn.restart();
        lastSection = section;
        if (section === ControlPanel.Section.Claude)
            ClaudeUsage.refresh(false);
    }
    onViewChanged: {
        updateScanner();
        passwordNetwork = null;
        wifiError = "";
    }

    implicitWidth: 384
    implicitHeight: frame.implicitHeight + gap
    dismissible: true

    Timer {
        id: btScanTimeout
        interval: 30000
        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false;
        }
    }

    // A section's place on the rail: a 32px tile over which the rail's marker glides when chosen
    // (its glyph gilt), else a muted glyph that lifts to text2 on the hover fill, or the state
    // colour it reports.
    component RailTile: Rectangle {
        id: tile

        required property int target
        property string icon
        property string name
        // A state the glyph reports while the section isn't chosen (alert: something failed).
        property bool reporting: false
        property color reportColor: Theme.alert
        // The VPN's dot, as on the bar's network glyph.
        property bool dot: false
        readonly property bool chosen: root.section === target

        implicitWidth: 32
        implicitHeight: 32
        radius: Theme.radiusRow
        // The chosen tile's fill is the marker under it; the pointer adds a little to it.
        color: chosen ? (area.containsMouse ? Theme.tint(Theme.gilt, 0.06) : "transparent") : area.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Accessible.role: Accessible.PageTab
        Accessible.name: name

        Icon {
            id: glyph
            anchors.centerIn: parent
            text: tile.icon
            color: tile.chosen ? Theme.gilt : tile.reporting ? tile.reportColor : area.containsMouse ? Theme.text2 : Theme.muted

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -3
                anchors.topMargin: 1
                width: 7
                height: 7
                radius: width / 2
                color: Theme.gilt
                border.width: 2
                border.color: Theme.inset
                opacity: tile.dot ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.section = tile.target
        }
    }

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: body.implicitHeight + 16

        RowLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            transform: Translate {
                id: settleShift
            }

            NumberAnimation {
                id: settle
                target: settleShift
                property: "y"
                from: -8
                to: 0
                duration: Theme.durationState
                easing.type: Theme.easing
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 40
                radius: Theme.radiusInset
                color: Theme.inset

                // The chosen section's 10% gilt tint, one for the rail, gliding to the tile picked
                // in Hyprland's switch time, as the workspace index does.
                Rectangle {
                    x: tiles.x
                    y: tiles.y + root.section * (32 + tiles.spacing)
                    width: 32
                    height: 32
                    radius: Theme.radiusRow
                    color: Theme.tint(Theme.gilt, 0.1)

                    Behavior on y {
                        enabled: root.visible
                        NumberAnimation {
                            duration: Theme.durationSwitch
                            easing.type: Theme.easing
                        }
                    }
                }

                Column {
                    id: tiles
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 4
                    spacing: 4

                    RailTile {
                        target: ControlPanel.Section.Sound
                        name: "Sound"
                        icon: Pipewire.defaultAudioSink?.audio?.muted ? Icons.volumeOff : Icons.volumeHigh
                    }

                    RailTile {
                        target: ControlPanel.Section.Display
                        name: "Display"
                        icon: Icons.brightness
                    }

                    RailTile {
                        target: ControlPanel.Section.Network
                        name: "Network"
                        icon: NetworkStatus.type === "wifi" ? Icons.wifi : NetworkStatus.type === "ethernet" ? Icons.ethernet : Icons.disconnected
                        reporting: NetworkStatus.type === "disconnected"
                        dot: Vpn.connected
                    }

                    RailTile {
                        target: ControlPanel.Section.Devices
                        name: "Devices"
                        icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                    }

                    RailTile {
                        target: ControlPanel.Section.System
                        name: "Nix"
                        icon: Icons.nixos
                        reporting: NixStatus.lastFailed || NixStatus.failedUnits.length > 0
                    }

                    RailTile {
                        target: ControlPanel.Section.Claude
                        name: "Claude"
                        icon: Icons.claude
                        reporting: ClaudeUsage.full
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Loader {
                    id: page
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.pageHeight
                    sourceComponent: {
                        switch (root.section) {
                        case ControlPanel.Section.Display:
                            return displayPage;
                        case ControlPanel.Section.Network:
                            return [networkPage, wifiPage, ethernetPage, vpnPage][root.view];
                        case ControlPanel.Section.Devices:
                            return devicesPage;
                        case ControlPanel.Section.System:
                            return systemPage;
                        case ControlPanel.Section.Claude:
                            return claudePage;
                        default:
                            return soundPage;
                        }
                    }
                    onLoaded: pageFade.restart()
                    transform: Translate {
                        id: pageShift
                    }

                    NumberAnimation {
                        id: pageFade
                        target: page
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }

                    NumberAnimation {
                        id: pageIn
                        target: pageShift
                        property: "y"
                        to: 0
                        duration: Theme.durationState
                        easing.type: Theme.easing
                    }
                }

                MediaPanel {
                    Layout.fillWidth: true
                    visible: Media.active
                    shown: root.visible
                    onPlayerFocused: root.visible = false
                }
            }
        }
    }

    Component {
        id: soundPage

        PanelPage {
            title: "Sound"

            VolumeControl {
                Layout.fillWidth: true
                shown: root.visible
            }
        }
    }

    Component {
        id: claudePage

        PanelPage {
            title: "Claude"
            detail: claudeView.updated

            ClaudeUsageView {
                id: claudeView
                Layout.fillWidth: true
                onLinkOpened: root.visible = false
            }
        }
    }

    Component {
        id: displayPage

        PanelPage {
            title: "Display"

            BrightnessControl {
                Layout.fillWidth: true
            }

            NightLightControl {
                Layout.fillWidth: true
            }

            // Screens go to a Chromecast through GNOME Network Displays (there is no open-source
            // AirPlay video sender); audio outputs, AirPlay included, are under Sound.
            PanelRow {
                Layout.topMargin: 4
                icon: Icons.cast
                label: "Cast screen"
                sublabel: "Chromecast, through GNOME Network Displays"
                canOpen: false
                canToggle: false
                onToggled: root.castScreen()
                onOpened: root.castScreen()
            }
        }
    }

    Component {
        id: networkPage

        PanelPage {
            title: "Network"

            // Shown for any wired device, and in place of WiFi when there is no network hardware at all.
            PanelRow {
                visible: NetworkStatus.wiredDevice !== null || NetworkStatus.wifiDevice === null
                icon: NetworkStatus.wiredConnected ? Icons.ethernet : Icons.disconnected
                on: NetworkStatus.wiredConnected
                label: "Ethernet"
                sublabel: {
                    const device = NetworkStatus.wiredDevice;
                    if (!device)
                        return "No network device";
                    if (device.connected)
                        return NetworkStatus.ip !== "" ? `Connected - ${NetworkStatus.ip}` : "Connected";
                    return device.hasLink ? "Not connected" : "Cable unplugged";
                }
                canOpen: NetworkStatus.wiredDevice !== null
                canToggle: false
                onOpened: root.view = ControlPanel.View.Ethernet
            }

            PanelRow {
                visible: NetworkStatus.wifiDevice !== null
                icon: Networking.wifiEnabled && Networking.wifiHardwareEnabled ? Icons.wifi : Icons.wifiOff
                on: Networking.wifiEnabled && Networking.wifiHardwareEnabled
                label: "WiFi"
                sublabel: !Networking.wifiHardwareEnabled ? "Off (hardware switch)" : NetworkStatus.wifiNetwork?.name ?? (Networking.wifiEnabled ? "Not connected" : "Off")
                canOpen: Networking.wifiEnabled && Networking.wifiHardwareEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onOpened: root.view = ControlPanel.View.Wifi
            }

            PanelRow {
                icon: Icons.vpn
                on: Vpn.connected
                label: "VPN"
                sublabel: root.vpnStatus()
                onToggled: Vpn.toggle()
                onOpened: {
                    Vpn.loadCountries();
                    root.view = ControlPanel.View.Vpn;
                }
            }

            BarText {
                visible: Vpn.error !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: Vpn.error
                color: Theme.alert
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }

    Component {
        id: wifiPage

        PanelPage {
            title: "WiFi networks"
            back: true
            onBackClicked: root.view = ControlPanel.View.Main

            BarText {
                visible: wifiList.count === 0
                Layout.leftMargin: 12
                text: "No networks found"
                color: Theme.text2
                font.pixelSize: 11
            }

            Repeater {
                id: wifiList

                model: ScriptModel {
                    values: (root.wifiDevice?.networks.values ?? []).filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                }

                ListRow {
                    id: wifiRow

                    required property WifiNetwork modelData

                    Layout.fillWidth: true
                    icon: modelData.security === WifiSecurityType.Open ? Icons.wifi : Icons.lock
                    label: modelData.name
                    sublabel: modelData.stateChanging ? "Connecting…" : `${Math.round(modelData.signalStrength * 100)}%`
                    active: modelData.connected || root.passwordNetwork === modelData
                    onClicked: root.connectWifi(modelData)

                    Connections {
                        target: wifiRow.modelData
                        function onConnectionFailed(reason) {
                            root.wifiFailed(wifiRow.modelData, reason);
                        }
                    }
                }
            }

            BarText {
                visible: root.wifiError !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: root.wifiError
                color: Theme.alert
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            PasswordField {
                visible: root.passwordNetwork !== null
                Layout.fillWidth: true
                title: `Password for ${root.passwordNetwork?.name ?? ""}`
                onSubmitted: password => {
                    root.wifiError = "";
                    root.passwordNetwork.connectWithPsk(password);
                    root.passwordNetwork = null;
                }
                onCancelled: root.passwordNetwork = null
            }
        }
    }

    Component {
        id: ethernetPage

        PanelPage {
            title: "Ethernet"
            back: true
            onBackClicked: root.view = ControlPanel.View.Main

            ConnectionDetails {
                Layout.fillWidth: true
                device: NetworkStatus.wiredDevice
            }
        }
    }

    Component {
        id: vpnPage

        PanelPage {
            title: "VPN countries"
            back: true
            onBackClicked: root.view = ControlPanel.View.Main

            BarText {
                visible: Vpn.countries.length === 0
                Layout.leftMargin: 12
                text: Vpn.loadingCountries ? "Loading…" : "No countries available. Signed out? Run protonvpn signin."
                color: Theme.text2
                font.pixelSize: 11
            }

            // The panel stays open while connecting, so the outcome lands where it was asked for.
            BarText {
                visible: text !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 2
                text: Vpn.error !== "" ? Vpn.error : Vpn.connecting || Vpn.disconnecting ? root.vpnStatus() : ""
                color: Vpn.error !== "" ? Theme.alert : Theme.text2
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            Repeater {
                model: Vpn.countries

                ListRow {
                    required property var modelData

                    Layout.fillWidth: true
                    emoji: true
                    icon: modelData.flag
                    label: modelData.name
                    sublabel: Vpn.connecting && Vpn.target === modelData.code ? "Connecting…" : modelData.code
                    // Gilt: the country the tunnel comes out in.
                    active: Vpn.connected && Vpn.country === modelData.code
                    onClicked: Vpn.connect(modelData.code)
                }
            }
        }
    }

    // Devices: the Bluetooth switch, the peripherals' batteries, then Bluetooth's devices under a
    // heading that carries the scan, connected first; a connected device's battery beside its state.
    Component {
        id: devicesPage

        PanelPage {
            id: devices

            readonly property bool on: root.adapter?.enabled ?? false
            readonly property bool scanning: root.adapter?.discovering ?? false
            readonly property var connected: (root.adapter?.devices.values ?? []).filter(d => d.connected)

            title: "Devices"

            PanelRow {
                visible: root.adapter !== null
                icon: devices.on ? Icons.bluetooth : Icons.bluetoothOff
                on: devices.on
                label: "Bluetooth"
                sublabel: {
                    if (!devices.on)
                        return "Off";
                    if (devices.connected.length === 1)
                        return `${devices.connected[0].name || devices.connected[0].address} connected`;
                    return devices.connected.length === 0 ? "On" : `${devices.connected.length} devices connected`;
                }
                canOpen: false
                onToggled: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
            }

            DeviceBatteries {
                Layout.fillWidth: true
                shown: root.visible
            }

            // The heading and, on its right, the scan: gilt on its tint while it runs ("on").
            RowLayout {
                visible: devices.on
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.rightMargin: 4
                Layout.bottomMargin: 2

                SectionLabel {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 0
                    text: "Bluetooth devices"
                }

                Rectangle {
                    implicitWidth: scanLabel.implicitWidth + 16
                    implicitHeight: 22
                    radius: Theme.radiusRow
                    color: devices.scanning ? Theme.tint(Theme.gilt, scanArea.containsMouse ? 0.16 : 0.1) : scanArea.containsMouse ? Theme.hover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

                    BarText {
                        id: scanLabel
                        anchors.centerIn: parent
                        text: devices.scanning ? "Scanning…" : "Scan"
                        color: devices.scanning ? Theme.gilt : scanArea.containsMouse ? Theme.text : Theme.text2
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.adapter)
                                return;
                            root.adapter.discovering = true;
                            btScanTimeout.restart();
                        }
                    }
                }
            }

            BarText {
                visible: devices.on && btList.count === 0
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: devices.scanning ? "Looking for devices nearby…" : "No devices yet. Scan to find one nearby."
                color: Theme.text2
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            Repeater {
                id: btList

                model: ScriptModel {
                    values: devices.on ? root.adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || a.address).localeCompare(b.name || b.address)) : []
                }

                ListRow {
                    required property BluetoothDevice modelData

                    Layout.fillWidth: true
                    icon: root.deviceGlyph(modelData)
                    label: modelData.name || modelData.address
                    sublabel: {
                        if (modelData.pairing)
                            return "Pairing…";
                        if (modelData.state === BluetoothDeviceState.Connecting)
                            return "Connecting…";
                        if (modelData.connected)
                            return modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)}%` : "Connected";
                        return modelData.paired ? "Paired" : "New";
                    }
                    active: modelData.connected
                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect();
                        } else {
                            modelData.trusted = true;
                            modelData.connect();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: systemPage

        PanelPage {
            title: "Nix"

            NixDetails {
                Layout.fillWidth: true
                onLinkOpened: root.visible = false
            }
        }
    }
}
