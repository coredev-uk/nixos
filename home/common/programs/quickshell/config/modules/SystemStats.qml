import QtQuick
import Quickshell.Services.UPower
import qs.common
import qs.services
import qs.widgets

Row {
    spacing: 6

    component Stat: CircularProgress {
        id: stat

        property string tooltip

        HoverHandler {
            id: hover
        }

        Tooltip {
            anchorItem: stat
            text: stat.tooltip
            active: hover.hovered
        }
    }

    Stat {
        value: SystemUsage.cpu
        color: Theme.sky
        icon: Icons.cpu
        tooltip: `CPU ${SystemUsage.cpu.toFixed(1)}%`
    }

    Stat {
        value: SystemUsage.memory
        color: Theme.mauve
        icon: Icons.memory
        tooltip: `RAM ${SystemUsage.memory.toFixed(1)}%`
    }

    Stat {
        value: SystemUsage.disk
        color: Theme.peach
        icon: Icons.disk
        tooltip: `Disk ${SystemUsage.disk.toFixed(1)}%`
    }

    Stat {
        readonly property UPowerDevice battery: UPower.displayDevice
        readonly property bool charging: battery?.state === UPowerDeviceState.Charging

        visible: battery?.isLaptopBattery ?? false
        value: (battery?.percentage ?? 0) * 100
        color: Theme.green
        icon: charging ? Icons.batteryCharging : value > 75 ? Icons.battery : value > 50 ? Icons.battery70 : value > 25 ? Icons.battery50 : Icons.battery20
        tooltip: `Battery ${Math.round(value)}% (${UPowerDeviceState.toString(battery?.state ?? UPowerDeviceState.Unknown)})`
    }
}
