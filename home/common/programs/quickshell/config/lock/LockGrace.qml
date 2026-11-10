import QtQuick
import qs.common

// Top-left, while an idle lock's grace is open (LockContext): says input brings you straight
// back, over a track in the day arc's style that drains, linearly, to the moment the password is
// needed again. Gone with the rest on the unlock, and on its own when the window closes.
Item {
    id: root

    required property AuthContext context
    property real s: 1
    property real margin: 80

    readonly property real trackWidth: Math.round(360 * s)

    Column {
        x: root.margin
        y: root.margin
        spacing: Math.round(14 * root.s)

        Text {
            text: "Move or press any key to return"
            color: Theme.text2
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(22 * root.s)
            font.weight: Font.Medium
        }

        Rectangle {
            width: root.trackWidth
            height: Math.round(3 * root.s)
            color: Theme.rule

            Rectangle {
                id: remaining

                // Of the window, still to come; a fraction, so the width follows the scale
                // once the surface has its size.
                property real share: 0

                width: Math.round(parent.width * share)
                height: parent.height
                color: Theme.tint(Theme.text, 0.42)

                // Surfaces are made as the lock starts, so the window is all still to come.
                Component.onCompleted: {
                    const ms = root.context.graceUntil - Date.now();
                    if (!root.context.graceOpen || ms <= 0)
                        return;
                    share = 1;
                    drain.duration = ms;
                    drain.start();
                }

                NumberAnimation {
                    id: drain

                    target: remaining
                    property: "share"
                    to: 0
                    easing.type: Easing.Linear
                }
            }
        }
    }
}
