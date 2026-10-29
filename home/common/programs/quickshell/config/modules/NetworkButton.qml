import QtQuick
import qs.common
import qs.services
import qs.widgets

// Connected is the normal state, so it stays enamel; disconnected is the alert. Gilt while its
// panel is open. A gilt dot on the glyph's corner says the VPN is on.
Icon {
    id: root

    // For the low-battery glyph, whose chips live in this panel.
    function openPanel() {
        if (!panel.visible)
            panel.toggle();
    }

    color: panel.visible ? Theme.gilt : NetworkStatus.type === "disconnected" ? Theme.alert : area.containsMouse ? Theme.text : Theme.text2
    text: {
        switch (NetworkStatus.type) {
        case "ethernet":
            return Icons.ethernet;
        case "wifi":
            const s = NetworkStatus.signal;
            return s >= 0.8 ? Icons.wifiStrength4 : s >= 0.6 ? Icons.wifiStrength3 : s >= 0.4 ? Icons.wifiStrength2 : s >= 0.2 ? Icons.wifiStrength1 : Icons.wifiStrength0;
        default:
            return Icons.disconnected;
        }
    }

    // The ground ring keeps the dot apart from the glyph under it, as on the day arc.
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -3
        anchors.topMargin: 1
        width: 8
        height: 8
        radius: 4
        color: Theme.gilt
        border.width: 2
        border.color: Theme.ground
        opacity: Vpn.connected ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !panel.visible
        text: {
            const network = NetworkStatus.type === "disconnected" ? "Disconnected" : NetworkStatus.ip ? `${NetworkStatus.name} (${NetworkStatus.ip})` : NetworkStatus.name;
            if (Vpn.connecting)
                return `${network} · Connecting to ${Vpn.target === "" ? "the VPN" : Vpn.countryName(Vpn.target)}…`;
            if (!Vpn.connected)
                return network;
            const where = Vpn.country === "" ? Vpn.server : `${Vpn.countryName(Vpn.country)}${Vpn.server === "" ? "" : ` (${Vpn.server})`}`;
            return `${network} · VPN on${where === "" ? "" : ` - ${where}`}`;
        }
    }

    NetworkPanel {
        id: panel
        anchorItem: root
    }
}
