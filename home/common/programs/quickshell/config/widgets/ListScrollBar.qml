import QtQuick
import QtQuick.Controls
import qs.common

// Thin scrollbar for panel lists; always shown while the content overflows.
ScrollBar {
    id: root

    policy: size < 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    padding: 0
    implicitWidth: 6

    background: Item {}

    contentItem: Rectangle {
        implicitWidth: 4
        radius: 2
        color: root.pressed ? Theme.muted : Theme.rule
    }
}
