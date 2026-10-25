import QtQuick
import qs.common
import qs.services
import qs.widgets

// Shares the Brightness service with the OSD so both show the same value. The monitors can also
// be changed from their own buttons, so the value is re-read whenever the row is created (each
// time the panel's main view opens).
SliderRow {
    icon: Icons.brightness
    color: Theme.yellow
    value: Brightness.percent

    Component.onCompleted: Brightness.refresh()

    onMoved: value => Brightness.set(value)
}
