import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.common
import qs.services
import qs.widgets

BarPopup {
    id: root

    enum View {
        Main,
        Wifi,
        Vpn,
        Bluetooth
    }

    property int view: NetworkPanel.View.Main
    readonly property var wifiDevice: NetworkStatus.wifiDevice
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // Secured network waiting for a password, and the last connection error.
    property WifiNetwork passwordNetwork: null
    property string wifiError: ""

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

    onOpening: view = NetworkPanel.View.Main
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
            sourceComponent: [mainView, wifiView, vpnView, bluetoothView][root.view]
        }
    }

    Component {
        id: mainView

        ColumnLayout {
            spacing: 4

            VolumeControl {
                Layout.fillWidth: true
            }

            BrightnessControl {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
            }

            PanelRow {
                // Hidden rather than greyed out when there is no usable WiFi hardware.
                visible: NetworkStatus.hasWifi
                icon: Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff
                iconColor: Theme.green
                label: "WiFi"
                sublabel: NetworkStatus.wifiNetwork?.name ?? (Networking.wifiEnabled ? "Not connected" : "Off")
                canOpen: Networking.wifiEnabled
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

            MediaCard {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: Media.active
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
}
