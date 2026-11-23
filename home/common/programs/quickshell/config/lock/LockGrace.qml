import QtQuick
import qs.common

// Top-left while an idle lock's grace is open (LockContext): input brings you back, over a track
// that drains linearly to when the password is needed again.
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

                // Fraction still to come, so the width follows the scale once the surface is sized.
                property real share: 0

                width: Math.round(parent.width * share)
                height: parent.height
                color: Theme.tint(Theme.text, 0.42)

                // Surfaces are made as the lock starts: all of the window is still to come.
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
