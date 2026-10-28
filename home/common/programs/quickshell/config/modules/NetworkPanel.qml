import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs.common
import qs.services
import qs.widgets

BarPopup {
    id: root

    enum View {
        Main,
        Wifi,
        Ethernet,
        Vpn,
        Bluetooth,
        Cast
    }

    property int view: NetworkPanel.View.Main
    readonly property var wifiDevice: NetworkStatus.wifiDevice
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // Secured network waiting for a password, and the last connection error.
    property WifiNetwork passwordNetwork: null
    property string wifiError: ""
    // Per-app volume list under the volume slider; kept while the panel is reopened.
    property bool mixerExpanded: false
    // This computer's outputs for the Cast view; AirPlay's sink feeds OwnTone, whose speakers are
    // listed separately.
    readonly property var localOutputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio && node !== AirPlay.sink).sort((a, b) => outputName(a).localeCompare(outputName(b)))
    readonly property PwNode output: Pipewire.defaultAudioSink

    function outputName(node: PwNode): string {
        return node.description || node.nickname || node.name;
    }

    function updateScanner() {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible && view === NetworkPanel.View.Wifi;
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
        wifiError = `Couldn't connect to ${network.name}: ${ConnectionFailReason.toString(reason)}`;
        // Missing or rejected secrets: ask for the password again.
        if (network.security !== WifiSecurityType.Open && (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiClientFailed))
            passwordNetwork = network;
    }

    onOpening: {
        view = NetworkPanel.View.Main;
        AirPlay.refresh();
    }
    onVisibleChanged: updateScanner()
    onViewChanged: {
        updateScanner();
        passwordNetwork = null;
        wifiError = "";
    }

    implicitWidth: 320
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

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: content.implicitHeight + 24
        radius: 12
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        Loader {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: [mainView, wifiView, ethernetView, vpnView, bluetoothView, castView][root.view]
        }
    }

    Component {
        id: mainView

        ColumnLayout {
            spacing: 4

            VolumeControl {
                Layout.fillWidth: true
                expanded: root.mixerExpanded
                onExpandToggled: root.mixerExpanded = !root.mixerExpanded
            }

            BrightnessControl {
                Layout.fillWidth: true
            }

            NightLightControl {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
            }

            // Shown for any wired device, and in place of WiFi when there is no network hardware at all.
            PanelRow {
                visible: NetworkStatus.wiredDevice !== null || NetworkStatus.wifiDevice === null
                icon: NetworkStatus.wiredConnected ? Icons.ethernet : Icons.disconnected
                iconColor: NetworkStatus.wiredConnected ? Theme.green : Theme.overlay0
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
                onOpened: root.view = NetworkPanel.View.Ethernet
            }

            PanelRow {
                visible: NetworkStatus.wifiDevice !== null
                icon: Networking.wifiEnabled && Networking.wifiHardwareEnabled ? Icons.wifi : Icons.wifiOff
                iconColor: Theme.green
                label: "WiFi"
                sublabel: !Networking.wifiHardwareEnabled ? "Off (hardware switch)" : NetworkStatus.wifiNetwork?.name ?? (Networking.wifiEnabled ? "Not connected" : "Off")
                canOpen: Networking.wifiEnabled && Networking.wifiHardwareEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onOpened: root.view = NetworkPanel.View.Wifi
            }

            PanelRow {
                icon: Icons.vpn
                iconColor: Theme.mauve
                label: "VPN"
                sublabel: Vpn.connected ? `Connected - ${Vpn.server}` : "Disconnected"
                onToggled: Vpn.toggle()
                onOpened: {
                    Vpn.loadCountries();
                    root.view = NetworkPanel.View.Vpn;
                }
            }

            PanelRow {
                visible: root.adapter !== null
                icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                iconColor: Theme.blue
                label: "Bluetooth"
                sublabel: root.adapter?.enabled ? "On" : "Off"
                canOpen: root.adapter?.enabled ?? false
                onToggled: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
                onOpened: root.view = NetworkPanel.View.Bluetooth
            }

            // The icon stops casting; the row opens the speaker list and screen casting.
            PanelRow {
                icon: AirPlay.casting ? Icons.castConnected : Icons.cast
                iconColor: Theme.teal
                label: "Cast"
                sublabel: AirPlay.casting && AirPlay.chosen.length > 0 ? `AirPlay - ${AirPlay.chosen.map(speaker => speaker.name).join(", ")}` : "AirPlay speakers and screen"
                canToggle: AirPlay.casting
                onToggled: AirPlay.stop()
                onOpened: root.view = NetworkPanel.View.Cast
            }

            DeviceBatteries {
                Layout.fillWidth: true
                Layout.topMargin: 4
                shown: root.visible
            }

            MediaCard {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: Media.active
                onPlayerFocused: root.visible = false
            }
        }
    }

    Component {
        id: wifiView

        ColumnLayout {
            spacing: 4

            BackButton {
                title: "WiFi Networks"
                onClicked: root.view = NetworkPanel.View.Main
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                clip: true
                ScrollBar.vertical: ListScrollBar {}
                spacing: 2
                model: ScriptModel {
                    values: (root.wifiDevice?.networks.values ?? []).filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                }
                delegate: ListRow {
                    id: wifiRow

                    required property WifiNetwork modelData

                    width: ListView.view.width - (ListView.view.ScrollBar.vertical.visible ? 10 : 0)
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
                color: Theme.red
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
        id: ethernetView

        ColumnLayout {
            spacing: 4

            BackButton {
                title: "Ethernet"
                onClicked: root.view = NetworkPanel.View.Main
            }

            ConnectionDetails {
                Layout.fillWidth: true
                device: NetworkStatus.wiredDevice
            }
        }
    }

    Component {
        id: vpnView

        ColumnLayout {
            spacing: 4

            BackButton {
                title: "VPN Countries"
                onClicked: root.view = NetworkPanel.View.Main
            }

            BarText {
                visible: Vpn.countries.length === 0
                Layout.leftMargin: 12
                text: Vpn.loadingCountries ? "Loading…" : "No countries available (signed in to protonvpn?)"
                color: Theme.subtext0
                font.pixelSize: 12
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                clip: true
                ScrollBar.vertical: ListScrollBar {}
                spacing: 2
                model: Vpn.countries
                delegate: ListRow {
                    required property var modelData

                    width: ListView.view.width - (ListView.view.ScrollBar.vertical.visible ? 10 : 0)
                    emoji: true
                    icon: modelData.flag
                    label: modelData.name
                    sublabel: modelData.code
                    onClicked: {
                        Vpn.connect(modelData.code);
                        root.visible = false;
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothView

        ColumnLayout {
            spacing: 4

            BackButton {
                title: "Bluetooth Devices"
                onClicked: root.view = NetworkPanel.View.Main
            }

            ListRow {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                icon: Icons.search
                label: root.adapter?.discovering ? "Scanning…" : "Scan for devices"
                active: true
                accent: Theme.blue
                onClicked: {
                    if (!root.adapter)
                        return;
                    root.adapter.discovering = true;
                    btScanTimeout.restart();
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                clip: true
                ScrollBar.vertical: ListScrollBar {}
                spacing: 2
                model: ScriptModel {
                    values: (root.adapter?.devices.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || a.address).localeCompare(b.name || b.address))
                }
                delegate: ListRow {
                    required property BluetoothDevice modelData

                    width: ListView.view.width - (ListView.view.ScrollBar.vertical.visible ? 10 : 0)
                    icon: modelData.connected ? Icons.bluetoothConnected : Icons.bluetooth
                    label: modelData.name || modelData.address
                    sublabel: modelData.pairing ? "Pairing…" : modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
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
        id: castView

        ColumnLayout {
            spacing: 4

            Component.onCompleted: AirPlay.watching = true
            Component.onDestruction: AirPlay.watching = false

            BackButton {
                title: "Cast"
                onClicked: root.view = NetworkPanel.View.Main
            }

            BarText {
                Layout.leftMargin: 12
                text: "This computer"
                color: Theme.subtext0
                font.pixelSize: 11
            }

            Repeater {
                model: ScriptModel {
                    values: root.localOutputs
                }

                ListRow {
                    required property PwNode modelData
                    // GNOME Network Displays leaves its sink behind; picking it sends audio along
                    // with a screen cast.
                    readonly property bool screenCast: modelData.name.startsWith("gnome_network_displays")

                    Layout.fillWidth: true
                    icon: screenCast ? Icons.monitorShare : Icons.speaker
                    label: screenCast ? "Screen cast" : root.outputName(modelData)
                    sublabel: screenCast ? "With Cast screen" : ""
                    active: modelData === root.output
                    accent: Theme.teal
                    onClicked: {
                        if (AirPlay.casting)
                            AirPlay.select([]);
                        AirPlay.playOn(modelData);
                    }
                }
            }

            BarText {
                Layout.leftMargin: 12
                Layout.topMargin: 6
                text: "AirPlay"
                color: Theme.subtext0
                font.pixelSize: 11
            }

            // Several can play at once (multi-room); they play about a second late, so it suits music.
            Repeater {
                model: ScriptModel {
                    values: AirPlay.speakers
                    objectProp: "id"
                }

                ListRow {
                    required property var modelData

                    Layout.fillWidth: true
                    icon: Icons.speakerWireless
                    label: modelData.name
                    sublabel: modelData.failed ? "Couldn't connect" : modelData.chosen ? (AirPlay.casting ? "Playing" : "Selected") : ""
                    active: modelData.chosen && AirPlay.casting
                    accent: Theme.teal
                    onClicked: AirPlay.toggleSpeaker(modelData)
                }
            }

            // The first connection to a TV shows a code on its screen.
            Repeater {
                model: ScriptModel {
                    values: AirPlay.speakers.filter(speaker => speaker.needsPin)
                    objectProp: "id"
                }

                PasswordField {
                    required property var modelData

                    Layout.fillWidth: true
                    title: `Code shown on ${modelData.name}, if any`
                    onSubmitted: pin => AirPlay.submitPin(modelData, pin)
                    onCancelled: AirPlay.toggle(modelData)
                }
            }

            BarText {
                visible: text !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                text: {
                    if (!AirPlay.available)
                        return "AirPlay isn't running (the owntone user service)";
                    if (AirPlay.error !== "")
                        return AirPlay.error;
                    return AirPlay.speakers.length === 0 ? "No AirPlay speakers found on the network" : "";
                }
                color: AirPlay.available && AirPlay.error === "" ? Theme.overlay0 : Theme.red
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            // Screen mirroring goes over Chromecast: there is no open-source AirPlay video sender.
            ListRow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                icon: Icons.monitorShare
                label: "Cast screen"
                sublabel: "Chromecast"
                onClicked: {
                    Quickshell.execDetached(["gnome-network-displays"]);
                    root.visible = false;
                }
            }
        }
    }
}
