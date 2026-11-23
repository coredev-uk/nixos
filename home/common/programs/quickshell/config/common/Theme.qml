pragma Singleton

import QtQuick
import Quickshell

// Meridian palette; roles, not hues (DESIGN.md). Same values as `meridian` in lib/theme (system
// palette): change both.
Singleton {
    // Grounds, darkest to lightest: bar/backdrops `ground`, popups `plate`, sections/controls in a
    // plate `inset`, `rule` for every 1px line.
    readonly property color ground: "#151920"
    readonly property color plate: "#222830"
    readonly property color inset: "#191d24"
    readonly property color hover: "#2d333e"
    readonly property color rule: "#363d49"
    readonly property color selection: "#47505e"

    // Enamel legends: primary, secondary (sublabels, values, timestamps), muted (idle/disabled).
    readonly property color text: "#ece5d3"
    readonly property color text2: "#a9a493"
    readonly property color muted: "#6d717a"

    // Gilt: "here" (focused workspace, selection, focus ring) and "on" (enabled services, unread);
    // also the one primary button per dialog.
    readonly property color gilt: "#c9a24f"
    readonly property color giltHover: "#d8b468"
    // Slider/progress fills: toned down so the fill never outshines the label.
    readonly property color fill: "#bdb9a9"

    // Alert: errors, destructive, critical, recording. Caution: low battery, Caps Lock. Ok: a just-happened success.
    readonly property color alert: "#e06c5a"
    readonly property color caution: "#e0954f"
    readonly property color ok: "#6fb39a"
    // Notification body links.
    readonly property color link: "#8fb0d3"

    // Categorical series (stats, network, calendars); never state.
    readonly property color series1: "#8fb0d3"
    readonly property color series2: "#6fb39a"
    readonly property color series3: "#d39a8f"
    readonly property color series4: "#a99ad6"

    // `c` at `alpha`: active-row tints (10%) and scrims.
    function tint(c: color, alpha: real): color {
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    readonly property string fontFamily: "Atkinson Hyperlegible Next"
    // Lock/greeter clock: same family, light, at display size.
    readonly property string displayFontFamily: "Atkinson Hyperlegible Next"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string emojiFont: "Noto Color Emoji"
    // Tabular figures so readouts don't shift.
    readonly property var fontFeatures: ({
            "tnum": 1
        })
    readonly property int fontSize: 14

    // Corner radii step down as surfaces nest.
    readonly property int radiusPlate: 10
    readonly property int radiusInset: 8
    readonly property int radiusRow: 6

    // Motion: state changes short, spatial moves longer, reveals longest; exits quicker than entries.
    // `durationSwitch` matches Hyprland's workspace switch (hyprland/config/animations.nix) for the bar's workspace index.
    readonly property int durationState: 160
    readonly property int durationExit: 120
    readonly property int durationSwitch: 150
    readonly property int durationMove: 300
    readonly property int durationReveal: 650
    readonly property int easing: Easing.OutCubic
    readonly property int easingExit: Easing.InCubic

    readonly property int barHeight: 24
    // Popups and menus open away from the bar's edge.
    readonly property bool barAtTop: true
    readonly property int popupEdges: barAtTop ? Edges.Bottom : Edges.Top
}
