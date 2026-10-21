import QtQuick
import Quickshell.Services.Pipewire
import qs.common
import qs.widgets

// Default sink volume; the icon toggles mute.
SliderRow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

    value: (sink?.audio?.volume ?? 0) * 100
    icon: muted ? Icons.volumeOff : value > 66 ? Icons.volumeHigh : value > 33 ? Icons.volumeMedium : Icons.volumeLow
    color: muted ? Theme.overlay0 : Theme.blue

    onMoved: value => {
        if (sink?.audio)
            sink.audio.volume = value / 100;
    }
    onIconClicked: {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
