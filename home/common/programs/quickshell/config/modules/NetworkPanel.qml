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

    function updateScanner() {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible && view === NetworkPanel.View.Wifi;
    }

    onOpening: view = NetworkPanel.View.Main
    onVisibleChanged: updateScanner()
    onViewChanged: updateScanner()

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

            PanelRow {
                icon: Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff
                iconColor: Theme.green
                label: "WiFi"
                sublabel: NetworkStatus.wifiNetwork?.name ?? (!NetworkStatus.hasWifi ? "No WiFi hardware" : Networking.wifiEnabled ? "Not connected" : "Off")
                dimmed: !NetworkStatus.hasWifi
                canOpen: NetworkStatus.hasWifi && Networking.wifiEnabled
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
                icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                iconColor: Theme.blue
                label: "Bluetooth"
                sublabel: root.adapter === null ? "No adapter" : root.adapter.enabled ? "On" : "Off"
                dimmed: root.adapter === null
                canOpen: root.adapter?.enabled ?? false
                onToggled: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
                onOpened: root.view = NetworkPanel.View.Bluetooth
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
                    required property WifiNetwork modelData

                    width: ListView.view.width - (ListView.view.ScrollBar.vertical.visible ? 10 : 0)
                    icon: modelData.security === WifiSecurityType.Open ? Icons.wifi : Icons.lock
                    label: modelData.name
                    sublabel: modelData.stateChanging ? "Connecting…" : `${Math.round(modelData.signalStrength * 100)}%`
                    active: modelData.connected
                    onClicked: {
                        if (!modelData.connected)
                            modelData.connect();
                    }
                }
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
