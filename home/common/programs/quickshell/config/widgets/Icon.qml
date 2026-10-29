import QtQuick
import qs.common

Text {
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: 16
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }
}
