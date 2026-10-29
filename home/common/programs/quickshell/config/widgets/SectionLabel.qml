import QtQuick
import QtQuick.Layouts
import qs.common

// 11px text2 heading that chunks a panel into groups ("Sound", "Display", "Network"). Groups
// after the first set a topMargin, so there is more room above a heading than below it.
BarText {
    Layout.leftMargin: 12
    Layout.bottomMargin: 2
    color: Theme.text2
    font.pixelSize: 11
}
