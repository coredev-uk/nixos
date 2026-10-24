pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Catppuccin Mocha
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color pink: "#f5c2e7"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color sky: "#89dceb"
    readonly property color sapphire: "#74c7ec"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"

    readonly property string fontFamily: "Inter"
    // Inter's optical size for large text (the lock screen clock).
    readonly property string displayFontFamily: "Inter Display"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string emojiFont: "Noto Color Emoji"
    readonly property int fontSize: 14

    readonly property int barHeight: 24
    // Screen edge the bar sits on; popups and menus open away from it.
    readonly property bool barAtTop: true
    readonly property int popupEdges: barAtTop ? Edges.Bottom : Edges.Top
}
