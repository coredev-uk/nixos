import QtQuick
import qs.common

// The navy plate every popup, menu and floating card is drawn on: plate ground, 1px rule,
// 10px corners. Floating windows (the OSD, dialogs) add the Float shadow themselves.
Rectangle {
    radius: Theme.radiusPlate
    color: Theme.plate
    border.color: Theme.rule
    border.width: 1
}
