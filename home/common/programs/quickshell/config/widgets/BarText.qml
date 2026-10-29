import QtQuick
import qs.common

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.features: Theme.fontFeatures
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationState
            easing.type: Theme.easing
        }
    }
}
