import QtQuick

// Rises into place and fades in when `shown` turns on, after `delay`; sinks and fades, without
// the delay, when it turns off (the unlock outro).
Item {
    id: reveal

    property bool shown: true
    property int delay: 0
    property real rise: 28

    opacity: shown ? 1 : 0
    transform: Translate {
        y: reveal.shown ? 0 : reveal.rise

        Behavior on y {
            SequentialAnimation {
                PauseAnimation {
                    duration: reveal.shown ? reveal.delay : 0
                }
                NumberAnimation {
                    duration: reveal.shown ? 650 : 360
                    easing.type: reveal.shown ? Easing.OutCubic : Easing.InCubic
                }
            }
        }
    }

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation {
                duration: reveal.shown ? reveal.delay : 0
            }
            NumberAnimation {
                duration: reveal.shown ? 650 : 360
                easing.type: reveal.shown ? Easing.OutCubic : Easing.InCubic
            }
        }
    }
}
