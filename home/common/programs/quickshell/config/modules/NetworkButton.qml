import QtQuick
import qs.common
import qs.services
import qs.widgets

// Connected is the normal state, so it stays enamel; disconnected is the alert. Gilt while its
// panel is open.
Icon {
    id: root

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

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        onClicked: panel.toggle()
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !panel.visible
        text: NetworkStatus.type === "disconnected" ? "Disconnected" : NetworkStatus.ip ? `${NetworkStatus.name} (${NetworkStatus.ip})` : NetworkStatus.name
    }

    NetworkPanel {
        id: panel
        anchorItem: root
    }
}
