pragma Singleton

import Quickshell

// Nerd Font Material Design glyphs (nf-md-*), see https://www.nerdfonts.com/cheat-sheet
Singleton {
    readonly property string workspace: String.fromCodePoint(0xF0765) // circle
    readonly property string workspaceActive: String.fromCodePoint(0xF043E) // radiobox_marked

    readonly property string cpu: String.fromCodePoint(0xF0EE0) // cpu_64_bit
    readonly property string memory: String.fromCodePoint(0xF035B) // memory
    readonly property string disk: String.fromCodePoint(0xF02CA) // harddisk
    readonly property string gpu: String.fromCodePoint(0xF08AE) // expansion_card

    readonly property string power: String.fromCodePoint(0xF0425) // power
    readonly property string logout: String.fromCodePoint(0xF0343) // logout
    readonly property string restart: String.fromCodePoint(0xF0709) // restart
    readonly property string sleep: String.fromCodePoint(0xF04B2) // sleep
    readonly property string coffee: String.fromCodePoint(0xF0176) // coffee
    readonly property string coffeeOff: String.fromCodePoint(0xF06CA) // coffee_outline
    readonly property string nightLight: String.fromCodePoint(0xF0594) // weather_night

    readonly property string battery: String.fromCodePoint(0xF0079) // battery
    readonly property string battery70: String.fromCodePoint(0xF0080) // battery_70
    readonly property string battery50: String.fromCodePoint(0xF007E) // battery_50
    readonly property string battery20: String.fromCodePoint(0xF007B) // battery_20
    readonly property string batteryCharging: String.fromCodePoint(0xF0084) // battery_charging

    readonly property string headphones: String.fromCodePoint(0xF02CB) // headphones
    readonly property string mouse: String.fromCodePoint(0xF037D) // mouse
    readonly property string keyboard: String.fromCodePoint(0xF030C) // keyboard

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
    readonly property string chevronUp: String.fromCodePoint(0xF0143) // chevron_up
    readonly property string chevronDown: String.fromCodePoint(0xF0140) // chevron_down
    readonly property string arrowRight: String.fromCodePoint(0xF0054) // arrow_right

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
    readonly property string music: String.fromCodePoint(0xF075A) // music
    readonly property string pause: String.fromCodePoint(0xF03E4) // pause

    readonly property string check: String.fromCodePoint(0xF012C) // check
    readonly property string close: String.fromCodePoint(0xF0156) // close
    readonly property string checkboxOn: String.fromCodePoint(0xF0132) // checkbox_marked
    readonly property string checkboxOff: String.fromCodePoint(0xF0131) // checkbox_blank_outline
    readonly property string radioOn: String.fromCodePoint(0xF043E) // radiobox_marked
    readonly property string radioOff: String.fromCodePoint(0xF043D) // radiobox_blank

    // OSD
    readonly property string microphone: String.fromCodePoint(0xF036C) // microphone
    readonly property string microphoneOff: String.fromCodePoint(0xF036D) // microphone_off

    // Polkit dialog
    readonly property string shieldLock: String.fromCodePoint(0xF099D) // shield_lock
    readonly property string account: String.fromCodePoint(0xF0004) // account
    readonly property string accountGroup: String.fromCodePoint(0xF0849) // account_group

    // Privacy indicators (microphone is shared with the OSD group above)
    readonly property string webcam: String.fromCodePoint(0xF05A0) // webcam
    readonly property string monitorShare: String.fromCodePoint(0xF1483) // monitor_share
    readonly property string waveform: String.fromCodePoint(0xF147D) // waveform
    readonly property string application: String.fromCodePoint(0xF08C6) // application

    // Notifications (bell, bellOff and close are shared with the groups above)
    readonly property string bellOutline: String.fromCodePoint(0xF009C) // bell_outline
    readonly property string notificationClearAll: String.fromCodePoint(0xF039F) // notification_clear_all
    readonly property string send: String.fromCodePoint(0xF048A) // send
}
