import QtQuick
import qs.common
import qs.services
import qs.widgets

// Shares the Brightness service with the OSD so both show the same value. The monitors can also
// be changed from their own buttons, so the panel re-reads it each time it opens.
SliderRow {
    icon: Icons.brightness
    color: Theme.fill
    value: Brightness.percent
    // 0% would read as a real value before the first read answers.
    valueText: Brightness.known ? `${Math.round(value)}%` : "…"

    onMoved: value => Brightness.set(value)
}
