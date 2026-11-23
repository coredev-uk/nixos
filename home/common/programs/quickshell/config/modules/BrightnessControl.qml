import QtQuick
import qs.common
import qs.services
import qs.widgets

// Shares the Brightness service with the OSD. Monitors also change from their own buttons, so it re-reads on open.
SliderRow {
    icon: Icons.brightness
    color: Theme.fill
    value: Brightness.percent
    // 0% would read as a real value before the first read.
    valueText: Brightness.known ? `${Math.round(value)}%` : "…"

    onMoved: value => Brightness.set(value)
}
