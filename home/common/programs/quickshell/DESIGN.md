---
name: Quickshell (atlas)
description: The desktop shell around Hyprland, keeping time like the Royal Observatory. A quiet night-slate instrument strip for working, a wide window for arriving and leaving.
colors:
  ground: "#151920"
  plate: "#222830"
  inset: "#191d24"
  hover: "#2d333e"
  rule: "#363d49"
  selection: "#47505e"
  text: "#ece5d3"
  text2: "#a9a493"
  muted: "#6d717a"
  gilt: "#c9a24f"
  giltHover: "#d8b468"
  fill: "#bdb9a9"
  alert: "#e06c5a"
  caution: "#e0954f"
  ok: "#6fb39a"
  link: "#8fb0d3"
  series1: "#8fb0d3"
  series2: "#6fb39a"
  series3: "#d39a8f"
  series4: "#a99ad6"
typography:
  display:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "300px"
    fontWeight: 300
    letterSpacing: "-0.03em"
    fontFeature: "\"tnum\" 1"
  headline:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "26px"
    fontWeight: 500
    fontFeature: "\"tnum\" 1"
  title:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "13px"
    fontWeight: 700
    fontFeature: "\"tnum\" 1"
  body-bar:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "14px"
    fontWeight: 400
    fontFeature: "\"tnum\" 1"
  body:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "12px"
    fontWeight: 400
    fontFeature: "\"tnum\" 1"
  label:
    fontFamily: "Atkinson Hyperlegible Next"
    fontSize: "11px"
    fontWeight: 400
    fontFeature: "\"tnum\" 1"
  icon:
    fontFamily: "Symbols Nerd Font"
    fontSize: "16px"
rounded:
  track: "2px"
  row: "6px"
  inset: "8px"
  plate: "10px"
  full: "9999px"
spacing:
  "4": "4px"
  "6": "6px"
  "8": "8px"
  "10": "10px"
  "12": "12px"
components:
  bar:
    backgroundColor: "{colors.ground}"
    textColor: "{colors.text}"
    typography: "{typography.body-bar}"
    height: "24px"
    padding: "0 10px 0 6px"
  plate:
    backgroundColor: "{colors.plate}"
    textColor: "{colors.text}"
    rounded: "{rounded.plate}"
    padding: "12px"
  inset-section:
    backgroundColor: "{colors.inset}"
    rounded: "{rounded.inset}"
    padding: "8px"
  list-row:
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.row}"
    padding: "8px 12px 8px 8px"
  list-row-hover:
    backgroundColor: "{colors.hover}"
  list-row-active:
    textColor: "{colors.gilt}"
  panel-row:
    textColor: "{colors.text}"
    typography: "{typography.title}"
    rounded: "{rounded.row}"
    height: "48px"
    padding: "0 8px"
  panel-row-hover:
    backgroundColor: "{colors.hover}"
  glyph-tile:
    backgroundColor: "{colors.inset}"
    textColor: "{colors.muted}"
    rounded: "{rounded.row}"
    size: "32px"
  glyph-tile-on:
    textColor: "{colors.gilt}"
  button-primary:
    backgroundColor: "{colors.gilt}"
    textColor: "{colors.ground}"
    typography: "{typography.body}"
    rounded: "{rounded.inset}"
  button-primary-hover:
    backgroundColor: "{colors.giltHover}"
  button-secondary:
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.inset}"
  button-secondary-hover:
    backgroundColor: "{colors.hover}"
  input-field:
    backgroundColor: "{colors.plate}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.row}"
    height: "28px"
    padding: "0 8px"
  slider-track:
    backgroundColor: "{colors.inset}"
    rounded: "{rounded.track}"
    height: "4px"
  slider-fill:
    backgroundColor: "{colors.fill}"
    rounded: "{rounded.track}"
  tooltip:
    backgroundColor: "{colors.plate}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.row}"
    padding: "5px 8px"
  day-arc:
    backgroundColor: "{colors.rule}"
    width: "120px"
    height: "8px"
  day-arc-now:
    backgroundColor: "{colors.gilt}"
    size: "7px"
---

# Design System: Quickshell (atlas)

## Overview

**Creative North Star: "Meridian"**

The shell keeps time like the Royal Observatory at Greenwich: night-slate grounds, enamel-cream legends, and gilt kept for "here" and "on", the way the Shepherd Gate clock keeps its gold for the hands. It is a quiet instrument of the day the wallpaper already follows. The person at it glances up, reads state in under a second, and nothing moved that didn't change. Nothing may create a sense of unease: no jitter, no flashes, no colour that isn't reporting something.

There are two registers. **The Instrument** is where the work happens: the 24px bar, its plates (panels, menus, tooltips, notifications), the OSD, the polkit dialog and Pass quick access. It is dense and settled; type runs 11–14px, rows line up on fixed glyph columns, and resting states are enamel and muted so a single gilt or alert glyph reads at once. **The Window** is for arriving and leaving: the lock screen, the greeter and the wallpaper picker. They go full-bleed over the wallpaper (and on the lock, its aerial clip), with a 300px light clock and slow, rising reveals. Both registers use the same palette, the same family and the same flat, tonal depth; only scale and pacing change.

The same palette is the system palette (`meridian` in `lib/theme/default.nix`), which Hyprland, Vicinae, Ghostty, Neovim, GTK, Qt and Discord read, so everything around the windows reads as one. Terminal programs (zellij, btop, fzf, bat, k9s, lazygit) take no palette of their own: they draw with the terminal's 16 colours, which Ghostty sets from it. `Theme.qml` and `lib/theme` hold the same values; a change goes in both.

Rejected outright: the pastel unixporn bar, the macOS glass menubar, glows, gradients and animated accent colour, and big-tile dashboards.

**Key Characteristics:**
- Night-slate grounds stepped by tone (ground → plate → inset, hover and rule above), every edge a 1px rule.
- Gilt means "you are here" or "this is on", and the one primary button. Nothing else is gold.
- Atkinson Hyperlegible Next everywhere, with tabular figures so readouts never shift.
- The day arc: the day as a 24-hour track with the daylight lit and a gilt dot at now, in the bar and on the lock.
- One easing family, OutCubic in and InCubic out: 160ms state changes, 120ms exits, 300ms spatial moves, 650ms Window reveals. Hyprland uses the same curves but runs quicker (150ms to open, switch or move, 100ms for focus, 80ms to close), because it sits between every keystroke and its window.

## Colors

Night slate and enamel, with one warm metal and a short list of state colours (`config/common/Theme.qml`, the same values as `meridian` in `lib/theme`). Surfaces take colours by role, never by hue.

### Primary
- **Gilt** (#c9a24f): "here" and "on". The focused monitor's active workspace numeral and its 2px rule, the bar item whose plate is open (now playing, date and time, network, power), focus rings on fields, the selected row in Pass, the picker's outline and today in the calendar; enabled services in the control panel, the VPN's dot on the network glyph and its connected country, Caffeine, night light, Do Not Disturb, the bell while something is unread (new since the centre was last open, or not handled from its popup), a charging battery, the now-dot on the day arc. Also the fill of the one primary button in a dialog and the lock's submit. The kept-notification count, the polkit shield and a reply's send glyph are enamel, never gilt.
- **Gilt Hover** (#d8b468): the primary button and the lock's submit under the pointer.

### Tertiary (state)
- **Alert** (#e06c5a): errors, destructive actions, critical notifications (their 1px border), recording, a disconnected network, a wrong password, Shut down.
- **Caution** (#e0954f): a value near its limit (system stats, low-ish battery), Caps Lock on the lock, Log out and Reboot while armed, a signed-out Pass in the calendar, a peripheral at 15% or below in the bar (the battery-alert glyph) and on its chip at 25% or below (the same glyph). Caution and gilt are almost equally bright, so caution never reports by hue alone: a stat near its limit is also underlined and its tooltip says "high" or "low"; a low battery adds the battery-alert glyph; Caps Lock and the armed power rows say their state in words.
- **Ok** (#6fb39a): a success that just happened: copied, accepted on the lock (the field edge and dots turn ok before everything sinks), the confirm check.
- **Link** (#8fb0d3): links in notification bodies.
- **Series 1–4** (#8fb0d3, #6fb39a, #d39a8f, #a99ad6): categorical only. System-stat series, network categories, calendar sources (Sonarr series1 by default). In the power menu, series1 and series2 tell the two Windows actions apart while armed. They never report state.

### Neutral
- **Ground** (#151920): the bar, full-screen backdrops (lock, greeter, picker), the scrim over a softened wallpaper (18% at rest, 42% engaged on the lock; 40% in the picker; 60% behind polkit), the label on a gilt button, the ring around the day-arc dot.
- **Plate** (#222830): every popup and floating surface (`Plate`): panels, menus, tooltips, the OSD, dialogs, notification popups. At 85% alpha for the lock's field, power buttons and today panel.
- **Inset** (#191d24): sections and controls inside a plate: glyph tiles, slider and progress tracks, the OSD artwork well, Pass and polkit fields, centre notification cards.
- **Hover** (#2d333e): the fill under the pointer on rows, back rows and secondary buttons.
- **Rule** (#363d49): every 1px line: plate borders, the bar's inner edge, separators, unfocused field borders, the day arc's night track, scrollbar thumbs, hover on a glyph tile.
- **Selection** (#47505e): text selection.
- **Text** (#ece5d3): primary legends and the bar's readouts; the day arc's lit span (42%) and ticks (70%).
- **Text2** (#a9a493): secondary: sublabels, values, timestamps, section headings, the bar's date and inactive workspaces.
- **Muted** (#6d717a): idle glyphs, chevrons, disabled and decorative things, days outside the month. Never text that carries information (that is text2), and never on a hover, selection or tint fill: an idle glyph, chevron or out-of-month day steps up to text2 while its row is hovered.
- **Fill** (#bdb9a9): slider and OSD level fills, enamel toned down so the fill never outshines its label.

### Named Rules
**The Here-or-On Rule.** Gilt appears only where you are (focused workspace, open panel's bar item, selection, focus ring, now on the arc) or where something is on (an enabled service, Caffeine, night light, DND, unread), plus the one primary button per dialog. If a gilt element is neither, it is wrong.

**The Roles, Not Hues Rule.** Every surface takes colour by what it means. Alert never decorates, ok never means "on", and a series colour never stands in for state.

**The Tint, Don't Fill Rule.** An active or selected row gets its accent at 10% alpha (16% under the pointer) behind accent-coloured glyph and label. A solid accent fill is only for the primary button.

## Typography

**Display Font:** Atkinson Hyperlegible Next, Light (the lock and greeter clock)
**Body Font:** Atkinson Hyperlegible Next
**Glyph Font:** Symbols Nerd Font; Noto Color Emoji where a row shows a flag or emoji

**Character:** One legible family set by size and weight alone. Tabular figures (`tnum`) everywhere, so the clock's colon and every readout hold still as digits turn.

### Hierarchy
- **Display** (300, `300px × s`, −0.03em): the lock and greeter clock, bottom-left. Its first digit's ink is measured and pulled onto the margin.
- **Headline** (500, `26px × s`): the lock's date and next sunrise/sunset line; 19–22px × s in the lock's prompt and today panel; 30px × s for the picker's title.
- **Title** (bold, 13px): panel-row titles, back-row titles, notification and card titles, the calendar month.
- **Body (bar)** (400, 14px, `Theme.fontSize`): everything in the bar; the time is bold, the active workspace numeral bold.
- **Body** (400, 12px): popup content, list rows, buttons, inputs, tooltips.
- **Label** (400, 11px): sublabels, values, timestamps, section headings.
- **Icon** (Symbols Nerd Font, 16px default; 14px in rows and buttons; 20px in the OSD).

### Named Rules
**The Three Steps Rule.** Popup text uses 13 bold / 12 / 11 and nothing else; hierarchy comes from those steps and the text → text2 → muted ramp.

**The Tabular Rule.** Every text item carries `Theme.fontFeatures` (`tnum`). Figures never change width.

**The Scaled Window Rule.** Window-register sizes are `Math.round(n × s)` with `s = max(0.75, height / 1080)`, never fixed px.

## Layout

The bar is one 24px ground row per screen at the top edge (`Theme.barAtTop`) with a 1px rule along its inner edge. Left: workspace numerals (6px margin) and the window title (capped at 400px). Centre: now playing. Right, 10px margin and spacing: privacy | tray | stats | caffeine + low battery + network | date, day arc, time | notifications | power, split by 1px × 14px rule separators that hide with the item they separate. The clock group reads "Wed 28 Oct ─●─ 13:23". Every bar target is at least 24px wide and the full bar height, and every clickable bar item shows a pointing cursor; tray icons stay 15px inside a 25 × 24 target with a tooltip naming the app.

Plates hang from their bar item and open away from the bar edge with an 8px gap (6px for tooltips). Widths are fixed per surface: power menu 220, control panel 320, now playing 320, calendar 350, polkit and notification popups 420, Pass 560; the OSD is 300. Inner padding 12px; rows pad 8px vertically, 8px left and 12px right; panel rows are 48px. Glyph columns are fixed (20px in list rows, 28px in slider rows, 32px tiles in panel rows) so labels line up down a list. 24px is reserved for the room around a floating window's shadow.

Window-register surfaces are full-screen. The lock pins the clock bottom-left on an 80px × s margin with the date line (56px × s) under it; today's events and what's playing sit bottom-right, the power buttons take the music's place while the password is up. The picker is a centred carousel of slanted cards over the highlighted picture blurred full screen.

## Elevation & Depth

Flat by tone. Layers step ground (bar, backdrops) → plate (popups) → inset (sections, tracks, tiles), with hover and rule above, and every plate carries a 1px rule border. Only windows that float free of the bar get a shadow: the OSD, the polkit dialog and Pass quick access. Blur is reserved for full-screen backdrops (the lock's wallpaper while engaged, blur 0.7 × 64 and −0.2 saturation; the picker's, 0.6 × 48) and is always followed by a ground scrim.

### Shadow Vocabulary
- **Float** (MultiEffect: black, opacity 0.35, blur 1.0, vertical offset 8px, 24px window padding around the card): free-floating windows only.

### Named Rules
**The Anchored Stays Flat Rule.** Anything hanging from the bar (panels, menus, tooltips, notification popups) has no shadow. A shadow means the window floats on its own.

**The Blur Is Backdrop Rule.** Blur never sits behind a plate's content; it only softens a full-screen picture so type can sit on it.

## Shapes

Restrained rounding that steps down as surfaces nest: 10px for plates and floating cards (`radiusPlate`), 8px for inset sections, dialog buttons, centre cards and the lock's field and power buttons (`radiusInset`), 6px for rows, tiles, inputs, small buttons and tooltips (`radiusRow`), 2px for 4px tracks. Circles are for progress rings, the day-arc dot and the password dots. Strokes are 1px (plate borders, focus rings, the calendar's selected day), with two 2px exceptions: the active workspace's rule and the picker's gilt outline. The picker's cards are parallelograms leaning right.

## Motion

Motion says what changed and where it went, then stops. Everything arrives decelerating (`Theme.easing`, OutCubic; Hyprland's `settle`, the same curve as a bezier) and leaves accelerating, quicker than it came (`Theme.easingExit`, InCubic; Hyprland's `leave`). Nothing overshoots or pulses. The wrong-password shake is the one deliberate oscillation; the only loops are an overflowing title scrolling in the bar and the lock's aerial video, and both stop when hidden or idle.

- **State** (`Theme.durationState`, 160ms): every colour, hover fill, border and opacity change, including all legend and glyph colours (`BarText`, `Icon`).
- **Exit** (`Theme.durationExit`, 120ms): a notification popup leaving.
- **Switch** (`Theme.durationSwitch`, 150ms): the workspace index, in step with Hyprland's workspace switch.
- **Move** (`Theme.durationMove`, 300ms): the picker's carousel, the calendar's month.
- **Reveal** (`Theme.durationReveal`, 650ms in, 360ms out): the lock, the greeter and the picker only.

**Hyprland is quicker** (`home/common/desktop/hyprland/config/animations.nix`). It is in the way of every keystroke that opens, closes, moves or focuses a window, so its motion only shows where a thing went: 150ms to open a window, switch workspace (`slidefade 8%`) or reflow the tiling; 100ms for the border, inactive dim and shadow on focus and for layers and popups fading in; 80ms for any close.

Who animates what: Hyprland fades whole surfaces in and out (windows, the bar's popups, Vicinae, Pass quick access, polkit, the picker), and the shell moves what's inside them (Pass and polkit settle the last 8px). The OSD and notification popups fade their own content out before their window goes (the OSD unloads 250ms after its fade, the popups' window unmaps once the last card has left), so Hyprland leaves those two layers alone (`no_anim`); a compositor fade on top would double the fade-in and come after the content had already gone. Inside a popup only opacity and translation animate, never size: Hyprland drops an xdg_popup that resizes every frame. A panel's plate snaps to its new height on a sub-view or expand, the content fades; the centre's stacks expand the same way, their revealed cards fading in.

### Named Rules
**The One Index Rule.** The workspace rule is a single index that glides to the new numeral while Hyprland slides the workspace in, in the same time on the same curve; the bar and the desktop tell one movement.

**The One Thing At A Time Rule.** Moving parts never cross. A new notification waits half a beat while the stack makes room; a leaving one goes first and the stack closes up after it. A panel's sub-view or menu level fades in after the switch, and a new month arrives from the side it lies on.

## Components

### Buttons
Quiet until touched.
- **Shape:** 8px in dialogs; 28px square icon buttons at 6px.
- **Primary:** gilt fill, ground label, 12px; giltHover under the pointer. One per dialog (polkit, Pass).
- **Secondary:** transparent with a 1px rule border and text label; hover fill.
- **Icon buttons:** 28px plate squares with a rule border, glyph in its state colour (ok check, alert cross); hover fill.
- **Disabled:** 50% opacity, faded over 160ms.

### Cards / Containers (Plate)
- **Corner Style:** 10px.
- **Background:** plate; inset for sections inside it. A centre notification card is inset at 8px, and its inner groups step back to plate.
- **Shadow Strategy:** none when anchored; Float when free.
- **Border:** 1px rule; alert on a critical notification.
- **Internal Padding:** 12px (plate), 8px (inset section).

### Inputs / Fields
- **Style:** 28px, 6px radius, 8px side padding, 12px text, a 1px rule border; plate inside an inset section (`PasswordField`), inset in polkit and Pass.
- **Focus:** the border turns gilt over 160ms.
- **Error:** the border turns alert, and the polkit card (and the lock's field) shakes horizontally on a wrong password.
- **Placeholder:** text2 unless the field has a visible label. Polkit's reads "Checking…" while PAM works, its lock glyph lifting from muted to text2 (alert on a wrong password).

### Lists and Rows
- **List row** (`ListRow`: networks, VPN countries, devices, power actions): transparent at rest, hover fill under the pointer. Active or armed: accent tint at 10% (16% hovered), glyph and label in the accent (gilt by default). Glyph column 20px (14px muted glyph), label 12px eliding, sublabel 11px text2.
- **Panel row** (`PanelRow`, the control panel's service rows): 48px. A 32px inset glyph tile toggles the service (gilt glyph when on, rule fill on hover), the rest opens its sub-view, marked with a muted chevron. Rows that launch something (Cast screen) have no chevron. 13px bold title over an 11px text2 sublabel.
- **Back row** (`BackButton`): muted chevron-left (text2 on hover) and a 13px bold title, heading every sub-view.
- **Section label** (`SectionLabel`): 11px text2 heading, 12px inset, 8px above (except the first), 2px below. The control panel: Sound, Display, Network, Devices. The outputs inset: This computer, AirPlay, Apps.
- **Two-click confirm:** Lock and Suspend run on the first click. The rest arm on the first click, tinting in their hue (caution for Log out and Reboot, alert for Shut down, series1/series2 for the Windows actions) with the label turning to "Click again to …", and run on the second.

### Sliders
- **Track:** 4px inset, 2px radius, enamel fill (`fill`); muted when the thing it sets is off. Click, drag, or wheel in 5% steps.
- **Slider row:** 28px glyph column (an app icon replaces it; its click area at least 24px tall), optional 80px text2 label, the track, a 38px right-aligned 11px value, and a 24px chevron slot kept on every row so tracks and values line up. An optional 11px text2 sublabel runs under the track to the value's end (the output's name on the volume row); on an expandable row it expands too. A muted output or app shows "Muted" as its value rather than dimming its name.

### Navigation (Workspaces)
Numerals, each at least 22px wide. Inactive: text2 (text on hover). Active: bold over a 14×2px rule at the bar's inner edge; gilt numeral and gilt rule while its monitor has focus, text over a muted rule on the other screen. The rule is one index for the row: it glides to the new numeral and turns gilt or muted as focus moves between screens, both over 150ms with Hyprland's switch (The One Index Rule).

### Tooltip
A 6px plate with a 1px rule border, 12px text, after a 400ms hover; wraps past 360px. A popup, because the 24px bar window can't hold one.

### Control panel, now playing
One panel behind the network glyph holds everything daily, in sections: Sound (the volume row named by its output, whose chevron, or the name, opens an inset with the outputs, this computer's sinks and AirPlay speakers with their code prompts, and per-app volumes), Display (brightness, night light), Network (Ethernet, WiFi, VPN), Devices (Bluetooth, Cast screen, the battery chips), then the media card. Clicking the now-playing track in either bar opens its media card in a 320px popup; the track turns gilt while it's open and stays in the bar until it closes.

### Bar badges
VPN on is an 8px gilt dot with a 2px ground ring on the network glyph's top-right; its tooltip names the country and server. While the VPN connects or disconnects, its row says so ("Connecting to UK…") and the panel stays open; a failure is an alert line with the reason under Network. A low peripheral is the battery-alert glyph in caution (alert at 10% or below), shown only while a device is at 15% or below and not charging; its tooltip names each device and level, and clicking it opens the control panel. The bell is gilt with a badge only while something is unread, the kept count beside it in text2, and its tooltip says "3 notifications, 1 new".

### On air
While an app captures the screen (`Privacy.onAir`), the trust surfaces keep personal detail off it. Pass quick access shows an inset strip (alert screen-share glyph, 11px text2: "Sharing your screen: usernames and vaults stay hidden until you open an item") and lists titles and types only, with no usernames, vaults or account, until an item is opened; a share starting with an item open goes back to the list. Notification popups hold off like Do Not Disturb and stay in the centre; critical ones still pop with the app name and "Critical notification", no body, image, actions or reply. Nothing re-pops when the share ends. On the lock, today's events show only their times and the music row is hidden. The bell's tooltip says "Popups held while sharing".

### OSD
A 300px floating plate above the bottom of the focused screen, with the Float shadow. Glyph in text, level in fill on an inset track, value in text2; glyph and fill go muted when muted, the value stays text2. Media shows artwork in a 40px inset well and a gilt play state. Rises and fades in over 160ms.

### Day Arc (signature)
The day as a 24-hour track: the night in rule, the daylight between today's sunrise and sunset lit in text at 42%, a tick at each (text at 70%), and a gilt dot with a ground ring at now. It says how much light is left; the wallpaper follows the same sun.
- **Bar:** 120×8px, inline between the date and the time, 2px track, 1×6px ticks, 7px dot. Hovering shows "Sunrise HH:mm · Sunset HH:mm"; any of the clock opens the calendar.
- **Lock / greeter:** `360 × s` wide under the clock in the date line, a `3 × s` track, `10 × s` ticks with their times (14px × s, text2) beneath, an `11 × s` dot; followed by the next sunrise or sunset.

### Lock / Greeter (Window register)
The wallpaper sharp at rest (the aerial clip playing on the lock) under an 18% ground scrim. Any key or click engages it: the picture blurs and desaturates over 600ms, the scrim deepens to 42%, and the date line gives way to a 460px × s plate-toned field with a dot per character and a gilt submit. The clock, prompt and today panel rise 28px × s and fade in over 650ms OutCubic, staggered 0 / 90 / 180ms (`Reveal`), and sink over 360ms InCubic on unlock. Power buttons (52px × s, 8px radius) run only after a 900ms hold, their armed hue (caution for restart, alert for shut down) growing from the centre.

### Wallpaper Picker (Window register)
Slanted parallelogram cards over the highlighted picture blurred full screen under a 40% ground scrim; side cards sit back under ground at 35%, the centred one wears a 2px gilt outline. The wallpaper itself crossfades over 1200ms InOutCubic when changed.

## Do's and Don'ts

### Do:
- **Do** take every colour, font and size from `Theme` (`qs.common`); change a palette value in `Theme.qml` and `lib/theme/default.nix` together.
- **Do** keep gilt to "here", "on" and the one primary button (The Here-or-On Rule).
- **Do** keep resting states enamel and muted, and let alert, caution and ok report state only.
- **Do** build depth with ground → plate → inset plus a 1px rule; add Float only to windows not anchored to the bar.
- **Do** animate with the `Theme` tokens (`durationState`, `durationExit`, `durationSwitch`, `durationMove`, `durationReveal`, `easing`, `easingExit`), and keep Hyprland's `animations.nix` quick: `durationSwitch` is its workspace time. The lock's own timings (the 600ms soften, the 900ms hold, the engage steps) and the 1200ms wallpaper crossfade are the authored exceptions.
- **Do** set every readout with tabular figures and fixed-width cells so nothing shifts as digits change.
- **Do** scale Window-register measurements with `s = max(0.75, height / 1080)`.

### Don't:
- **Don't** add anything that unsettles: jitter, flashes, pulsing accents, or motion for a change that didn't happen.
- **Don't** put blurred glass behind plates or bar content; blur is for full-screen backdrops only.
- **Don't** add glows, gradients or animated accent colour.
- **Don't** build big-tile dashboards or oversized toggle cards; controls are rows in a list.
- **Don't** use a series colour for state, or give a state colour a second meaning.
- **Don't** shadow an anchored plate, or fill anything solid gilt but the primary button.
