import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.common
import qs.services
import qs.widgets

// The control panel behind the network glyph: volume (its chevron opens the outputs and per-app
// volumes), brightness and night light, then Ethernet, WiFi and VPN, then Bluetooth, casting the
// screen and the peripherals' batteries, then what's playing.
BarPopup {
    id: root

    enum View {
        Main,
        Wifi,
        Ethernet,
        Vpn,
        Bluetooth
    }

    property int view: NetworkPanel.View.Main
    // Outputs and per-app volumes under the volume slider; kept while the panel is reopened.
    property bool expanded: false
    readonly property var wifiDevice: NetworkStatus.wifiDevice
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // Secured network waiting for a password, and the last connection error.
    property WifiNetwork passwordNetwork: null
    property string wifiError: ""

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
        const why = failReason(reason);
        wifiError = why === "" ? `Couldn't connect to ${network.name}.` : `Couldn't connect to ${network.name}: ${why}.`;
        // Missing or rejected secrets: ask for the password again.
        if (network.security !== WifiSecurityType.Open && (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiClientFailed))
            passwordNetwork = network;
    }

    onOpening: {
        view = NetworkPanel.View.Main;
        // The popup itself fades in on open; only switches while open fade the view.
        viewFade.complete();
        // Both can be changed outside the shell (monitor buttons, hyprsunset's schedule).
        Brightness.refresh();
        NightLight.refresh();
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

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: content.implicitHeight + 24

        Loader {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: [mainView, wifiView, ethernetView, vpnView, bluetoothView][root.view]
            onLoaded: viewFade.restart()
        }

        NumberAnimation {
            id: viewFade
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }

    Component {
        id: mainView

        ColumnLayout {
            spacing: 4

            SectionLabel {
                text: "Sound"
            }

            VolumeControl {
                Layout.fillWidth: true
                shown: root.visible
                expanded: root.expanded
                onExpandToggled: root.expanded = !root.expanded
            }

            SectionLabel {
                Layout.topMargin: 8
                text: "Display"
            }

            BrightnessControl {
                Layout.fillWidth: true
            }

            NightLightControl {
                Layout.fillWidth: true
            }

            SectionLabel {
                Layout.topMargin: 8
                text: "Network"
            }

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
                onOpened: root.view = NetworkPanel.View.Ethernet
            }

            PanelRow {
                visible: NetworkStatus.wifiDevice !== null
                icon: Networking.wifiEnabled && Networking.wifiHardwareEnabled ? Icons.wifi : Icons.wifiOff
                on: Networking.wifiEnabled && Networking.wifiHardwareEnabled
                label: "WiFi"
                sublabel: !Networking.wifiHardwareEnabled ? "Off (hardware switch)" : NetworkStatus.wifiNetwork?.name ?? (Networking.wifiEnabled ? "Not connected" : "Off")
                canOpen: Networking.wifiEnabled && Networking.wifiHardwareEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onOpened: root.view = NetworkPanel.View.Wifi
            }

            PanelRow {
                icon: Icons.vpn
                on: Vpn.connected
                label: "VPN"
                sublabel: root.vpnStatus()
                onToggled: Vpn.toggle()
                onOpened: {
                    Vpn.loadCountries();
                    root.view = NetworkPanel.View.Vpn;
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

            SectionLabel {
                Layout.topMargin: 8
                text: "Devices"
            }

            PanelRow {
                visible: root.adapter !== null
                icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                on: root.adapter?.enabled ?? false
                label: "Bluetooth"
                sublabel: root.adapter?.enabled ? "On" : "Off"
                canOpen: root.adapter?.enabled ?? false
                onToggled: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
                onOpened: root.view = NetworkPanel.View.Bluetooth
            }

            // Screens go to a Chromecast through GNOME Network Displays (there is no open-source
            // AirPlay video sender); audio outputs, AirPlay included, are under the volume row.
            PanelRow {
                icon: Icons.cast
                label: "Cast screen"
                sublabel: "Chromecast, through GNOME Network Displays"
                canOpen: false
                canToggle: false
                onToggled: root.castScreen()
                onOpened: root.castScreen()
            }

            DeviceBatteries {
                Layout.fillWidth: true
                Layout.topMargin: 4
                shown: root.visible
            }

            MediaCard {
                Layout.fillWidth: true
                Layout.topMargin: 8
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
                title: "WiFi networks"
                onClicked: root.view = NetworkPanel.View.Main
            }

            BarText {
                visible: wifiList.count === 0
                Layout.leftMargin: 12
                text: "No networks found"
                color: Theme.text2
                font.pixelSize: 11
            }

            ListView {
                id: wifiList

                visible: count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 250)
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
                title: "VPN countries"
                onClicked: root.view = NetworkPanel.View.Main
            }

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

            ListView {
                visible: count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 250)
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
                    sublabel: Vpn.connecting && Vpn.target === modelData.code ? "Connecting…" : modelData.code
                    // Gilt: the country the tunnel comes out in.
                    active: Vpn.connected && Vpn.country === modelData.code
                    onClicked: Vpn.connect(modelData.code)
                }
            }
        }
    }

    Component {
        id: bluetoothView

        ColumnLayout {
            spacing: 4

            BackButton {
                title: "Bluetooth devices"
                onClicked: root.view = NetworkPanel.View.Main
            }

            ListRow {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                icon: Icons.search
                label: root.adapter?.discovering ? "Scanning…" : "Scan for devices"
                active: root.adapter?.discovering ?? false
                onClicked: {
                    if (!root.adapter)
                        return;
                    root.adapter.discovering = true;
                    btScanTimeout.restart();
                }
            }

            BarText {
                visible: btList.count === 0 && !(root.adapter?.discovering ?? false)
                Layout.leftMargin: 12
                text: "No devices found"
                color: Theme.text2
                font.pixelSize: 11
            }

            ListView {
                id: btList

                visible: count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 220)
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
}
