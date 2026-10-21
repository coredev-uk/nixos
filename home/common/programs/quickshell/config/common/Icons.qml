pragma Singleton

import Quickshell

// Nerd Font Material Design glyphs (nf-md-*), see https://www.nerdfonts.com/cheat-sheet
Singleton {
    readonly property string workspace: String.fromCodePoint(0xF0765) // circle
    readonly property string workspaceActive: String.fromCodePoint(0xF043E) // radiobox_marked

    readonly property string cpu: String.fromCodePoint(0xF0EE0) // cpu_64_bit
    readonly property string memory: String.fromCodePoint(0xF035B) // memory
    readonly property string disk: String.fromCodePoint(0xF02CA) // harddisk

    readonly property string battery: String.fromCodePoint(0xF0079) // battery
    readonly property string battery70: String.fromCodePoint(0xF0080) // battery_70
    readonly property string battery50: String.fromCodePoint(0xF007E) // battery_50
    readonly property string battery20: String.fromCodePoint(0xF007B) // battery_20
    readonly property string batteryCharging: String.fromCodePoint(0xF0084) // battery_charging

    readonly property string wifi: String.fromCodePoint(0xF05A9) // wifi
    readonly property string wifiOff: String.fromCodePoint(0xF05AA) // wifi_off
    readonly property string wifiStrength0: String.fromCodePoint(0xF092F) // wifi_strength_outline
    readonly property string wifiStrength1: String.fromCodePoint(0xF091F) // wifi_strength_1
    readonly property string wifiStrength2: String.fromCodePoint(0xF0922) // wifi_strength_2
    readonly property string wifiStrength3: String.fromCodePoint(0xF0925) // wifi_strength_3
    readonly property string wifiStrength4: String.fromCodePoint(0xF0928) // wifi_strength_4
    readonly property string ethernet: String.fromCodePoint(0xF0200) // ethernet
    readonly property string disconnected: String.fromCodePoint(0xF0319) // lan_disconnect
    readonly property string lock: String.fromCodePoint(0xF033E) // lock
    readonly property string vpn: String.fromCodePoint(0xF099D) // shield_lock

    readonly property string bluetooth: String.fromCodePoint(0xF00AF) // bluetooth
    readonly property string bluetoothOff: String.fromCodePoint(0xF00B2) // bluetooth_off
    readonly property string bluetoothConnected: String.fromCodePoint(0xF00B1) // bluetooth_connect
    readonly property string search: String.fromCodePoint(0xF0349) // magnify

    readonly property string chevronLeft: String.fromCodePoint(0xF0141) // chevron_left
    readonly property string chevronRight: String.fromCodePoint(0xF0142) // chevron_right

    readonly property string bell: String.fromCodePoint(0xF009A) // bell
    readonly property string bellBadge: String.fromCodePoint(0xF116B) // bell_badge
    readonly property string bellOff: String.fromCodePoint(0xF009B) // bell_off

    readonly property string brightness: String.fromCodePoint(0xF00DF) // brightness_6
    readonly property string volumeHigh: String.fromCodePoint(0xF057E) // volume_high
    readonly property string volumeMedium: String.fromCodePoint(0xF0580) // volume_medium
    readonly property string volumeLow: String.fromCodePoint(0xF057F) // volume_low
    readonly property string volumeOff: String.fromCodePoint(0xF0581) // volume_off

    readonly property string previous: String.fromCodePoint(0xF04AE) // skip_previous
    readonly property string next: String.fromCodePoint(0xF04AD) // skip_next
    readonly property string play: String.fromCodePoint(0xF040A) // play
    readonly property string pause: String.fromCodePoint(0xF03E4) // pause

    readonly property string check: String.fromCodePoint(0xF012C) // check
    readonly property string close: String.fromCodePoint(0xF0156) // close
    readonly property string checkboxOn: String.fromCodePoint(0xF0132) // checkbox_marked
    readonly property string checkboxOff: String.fromCodePoint(0xF0131) // checkbox_blank_outline
    readonly property string radioOn: String.fromCodePoint(0xF043E) // radiobox_marked
    readonly property string radioOff: String.fromCodePoint(0xF043D) // radiobox_blank
}
