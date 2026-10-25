import QtQuick
import qs.common
import qs.services
import qs.widgets

// Night light slider: drag to pick a colour temperature for this session (further right is
// warmer, like macOS's Night Shift); the icon turns the night light off, and back onto the
// sunset schedule. "Auto" means following the schedule.
SliderRow {
    id: root

    readonly property int span: NightLight.neutral - NightLight.warmest

    function position(kelvin: int): real {
        return (NightLight.neutral - kelvin) / span * 100;
    }

    icon: Icons.nightLight
    color: NightLight.active ? Theme.peach : Theme.overlay0
    value: NightLight.custom > 0 ? position(NightLight.custom) : NightLight.scheduled ? position(NightLight.nightTemperature) : 0
    valueText: NightLight.custom > 0 ? `${NightLight.custom}K` : NightLight.scheduled ? "Auto" : "Off"

    Component.onCompleted: NightLight.refresh()
    onMoved: value => NightLight.setTemperature(NightLight.neutral - value / 100 * span)
    onIconClicked: NightLight.toggle()
}
