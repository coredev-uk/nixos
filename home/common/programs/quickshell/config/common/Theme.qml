pragma Singleton

import QtQuick
import Quickshell

// Meridian: the shell keeps time like the Royal Observatory at Greenwich. Night-navy grounds,
// enamel-cream legends, and gilt kept for "here" and "on". Roles, not hues: every surface takes
// its colours by what they mean (DESIGN.md). The same values are the system palette in
// lib/theme (`meridian`), which every other app reads; change them in both places.
Singleton {
    // Grounds, darkest to lightest. The bar and full-screen backdrops sit on `ground`, popups are
    // `plate`s, sections and controls inside a plate are `inset`, and `rule` draws every 1px line.
    readonly property color ground: "#0f1826"
    readonly property color plate: "#1a2638"
    readonly property color inset: "#121c2b"
    readonly property color hover: "#223149"
    readonly property color rule: "#2b3b54"
    readonly property color selection: "#3a4d6b"

    // Enamel legends: primary, secondary (sublabels, values, timestamps), and muted (idle
    // glyphs, chevrons, empty or disabled things).
    readonly property color text: "#ece5d3"
    readonly property color text2: "#a9a493"
    readonly property color muted: "#6d717a"

    // Gilt: you are here (focused workspace, selection, focus ring) and on (enabled services,
    // Caffeine, night light, Do Not Disturb, unread). Also the one primary button per dialog.
    readonly property color gilt: "#c9a24f"
    readonly property color giltHover: "#d8b468"
    // Slider and progress fills: enamel, toned down so the fill never outshines the label.
    readonly property color fill: "#bdb9a9"

    // State. Alert: errors, destructive actions, critical notifications, recording.
    // Caution: low-ish battery, Caps Lock. Ok: a success that just happened (copied, unlocked).
    readonly property color alert: "#e06c5a"
    readonly property color caution: "#e0954f"
    readonly property color ok: "#6fb39a"
    // Links in notification bodies.
    readonly property color link: "#8fb0d3"

    // Categorical series (system stats, network categories, calendar sources); never state.
    readonly property color series1: "#8fb0d3"
    readonly property color series2: "#6fb39a"
    readonly property color series3: "#d39a8f"
    readonly property color series4: "#a99ad6"

    // Translucent `c` at `alpha`, for tints behind an active row (10%) and scrims.
    function tint(c: color, alpha: real): color {
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    readonly property string fontFamily: "Atkinson Hyperlegible Next"
    // The lock and greeter clock: the same family, light, at display size.
    readonly property string displayFontFamily: "Atkinson Hyperlegible Next"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string emojiFont: "Noto Color Emoji"
    // Tabular figures everywhere, so readouts never shift as their digits change.
    readonly property var fontFeatures: ({
            "tnum": 1
        })
    readonly property int fontSize: 14

    // Corner radii step down as surfaces nest.
    readonly property int radiusPlate: 10
    readonly property int radiusInset: 8
    readonly property int radiusRow: 6

    // Motion: state changes are short, Window-register reveals long; one easing family.
    readonly property int durationState: 160
    readonly property int durationReveal: 650
    readonly property int easing: Easing.OutCubic

    readonly property int barHeight: 24
    // Screen edge the bar sits on; popups and menus open away from it.
    readonly property bool barAtTop: true
    readonly property int popupEdges: barAtTop ? Edges.Bottom : Edges.Top
}
