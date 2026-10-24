import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.common
import qs.services
import qs.widgets

// Left side of the password card: CPU, memory, GPU and disk dials.
GridLayout {
    id: root

    property real s: 1

    columns: 2
    rowSpacing: Math.round(12 * s)
    columnSpacing: Math.round(12 * s)

    GaugeTile {
        label: "CPU"
        value: SystemUsage.cpu
        accent: Theme.blue
    }

    GaugeTile {
        label: "Memory"
        value: SystemUsage.memory
        accent: Theme.mauve
    }

    GaugeTile {
        label: Gpu.available ? `GPU · ${Math.round(Gpu.temperature)}°C` : "GPU"
        value: Gpu.usage
        accent: Theme.green
        valueText: Gpu.available ? "" : "n/a"
    }

    GaugeTile {
        label: "Disk"
        value: SystemUsage.disk
        accent: Theme.peach
    }

    component GaugeTile: Tile {
        id: tile

        property string label
        property real value
        property color accent
        // Overrides the percentage (e.g. "n/a").
        property string valueText: ""
        // Eased copy of `value`, so the dial sweeps between samples.
        property real shown: value

        readonly property real ring: Math.round(84 * root.s)
        readonly property real thickness: Math.round(8 * root.s)

        Layout.fillWidth: true
        Layout.fillHeight: true
        s: root.s

        Behavior on shown {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutQuint
            }
        }

        Item {
            id: gauge

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(-12 * root.s)
            width: tile.ring
            height: tile.ring

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // Track, then the value, both on a 270° arc open at the bottom.
                ShapePath {
                    strokeColor: Theme.surface1
                    strokeWidth: tile.thickness
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: gauge.width / 2
                        centerY: gauge.height / 2
                        radiusX: (gauge.width - tile.thickness) / 2
                        radiusY: radiusX
                        startAngle: 135
                        sweepAngle: 270
                    }
                }

                ShapePath {
                    strokeColor: tile.accent
                    strokeWidth: tile.thickness
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: gauge.width / 2
                        centerY: gauge.height / 2
                        radiusX: (gauge.width - tile.thickness) / 2
                        radiusY: radiusX
                        startAngle: 135
                        sweepAngle: 2.7 * Math.max(0.5, Math.min(100, tile.shown))
                    }
                }
            }

            BarText {
                anchors.centerIn: parent
                text: tile.valueText || `${Math.round(tile.shown)}%`
                font.family: Theme.displayFontFamily
                font.pixelSize: Math.round(20 * root.s)
                font.weight: Font.Bold
            }
        }

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: gauge.bottom
            anchors.topMargin: Math.round(6 * root.s)
            text: tile.label
            color: Theme.subtext0
            font.pixelSize: Math.round(13 * root.s)
            font.weight: Font.Medium
        }
    }
}
