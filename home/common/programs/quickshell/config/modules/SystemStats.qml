import QtQuick
import Quickshell.Services.UPower
import qs.common
import qs.services
import qs.widgets

// Readouts, not gauges: a muted label and its value, the value in a fixed-width cell (its slack
// trailing) so the bar never shifts as digits change. A value turns caution near its limit.
Row {
    spacing: 8

    component Stat: Row {
        id: stat

        property string label
        property real value
        // The value as shown; percent unless set.
        property string valueText: `${Math.round(value)}%`
        property string widest: "100%"
        property bool high: value >= 90
        property string tooltip

        spacing: 4

        BarText {
            visible: stat.label !== ""
            text: stat.label
            color: Theme.text2
        }

        BarText {
            width: widestMetrics.advanceWidth
            horizontalAlignment: Text.AlignLeft
            text: stat.valueText
            color: stat.high ? Theme.caution : Theme.text

            TextMetrics {
                id: widestMetrics
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.features: Theme.fontFeatures
                text: stat.widest
            }
        }

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
        label: "CPU"
        value: SystemUsage.cpu
        tooltip: `CPU ${SystemUsage.cpu.toFixed(1)}%`
    }

    Stat {
        label: "RAM"
        value: SystemUsage.memory
        tooltip: `RAM ${SystemUsage.memory.toFixed(1)}%`
    }

    Stat {
        label: "Disk"
        value: SystemUsage.disk
        tooltip: `Disk ${SystemUsage.disk.toFixed(1)}%`
    }

    Stat {
        visible: Gpu.available
        label: "GPU"
        value: Gpu.usage
        tooltip: `GPU ${Math.round(Gpu.usage)}% · ${Math.round(Gpu.temperature)}°C`
    }

    Stat {
        visible: Gpu.available
        value: Gpu.temperature
        valueText: `${Math.round(value)}°C`
        widest: "100°C"
        high: value >= 85
        tooltip: "GPU temperature"
    }

    Stat {
        readonly property UPowerDevice battery: UPower.displayDevice
        readonly property bool charging: battery?.state === UPowerDeviceState.Charging

        visible: battery?.isLaptopBattery ?? false
        label: charging ? "Charging" : "Battery"
        value: (battery?.percentage ?? 0) * 100
        high: !charging && value <= 20
        tooltip: `Battery ${Math.round(value)}% (${UPowerDeviceState.toString(battery?.state ?? UPowerDeviceState.Unknown)})`
    }
}
