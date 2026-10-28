---
name: Quickshell (atlas)
description: The desktop shell around Hyprland. A dense instrument strip for working, a cinematic window for arriving and leaving.
colors:
  crust: "#11111b"
  mantle: "#181825"
  base: "#1e1e2e"
  surface0: "#313244"
  surface1: "#45475a"
  surface2: "#585b70"
  overlay0: "#6c7086"
  subtext0: "#a6adc8"
  subtext1: "#bac2de"
  text: "#cdd6f4"
  blue: "#89b4fa"
  lavender: "#b4befe"
  green: "#a6e3a1"
  red: "#f38ba8"
  peach: "#fab387"
  yellow: "#f9e2af"
  pink: "#f5c2e7"
  mauve: "#cba6f7"
  teal: "#94e2d5"
  sky: "#89dceb"
  sapphire: "#74c7ec"
typography:
  display:
    fontFamily: "Inter Display, Inter, sans-serif"
    fontSize: "300px"
    fontWeight: 500
    letterSpacing: "-0.04em"
    fontFeature: "\"case\" 1"
  headline:
    fontFamily: "Inter, sans-serif"
    fontSize: "26px"
    fontWeight: 500
  title:
    fontFamily: "Inter, sans-serif"
    fontSize: "13px"
    fontWeight: 700
  body-bar:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 400
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "11px"
    fontWeight: 400
  icon:
    fontFamily: "Symbols Nerd Font"
    fontSize: "16px"
rounded:
  xs: "3px"
  sm: "6px"
  md: "8px"
  lg: "10px"
  xl: "12px"
  full: "9999px"
spacing:
  "2": "2px"
  "4": "4px"
  "6": "6px"
  "8": "8px"
  "10": "10px"
  "12": "12px"
components:
  bar:
    backgroundColor: "{colors.crust}"
    textColor: "{colors.text}"
    typography: "{typography.body-bar}"
    height: "24px"
    padding: "0 10px"
  popup-panel:
    backgroundColor: "{colors.mantle}"
    textColor: "{colors.text}"
    rounded: "{rounded.xl}"
    padding: "12px"
  inset-section:
    backgroundColor: "{colors.base}"
    rounded: "{rounded.md}"
    padding: "8px"
  list-row:
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  list-row-hover:
    backgroundColor: "{colors.surface0}"
  list-row-active:
    textColor: "{colors.green}"
  panel-row:
    textColor: "{colors.text}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "10px 12px"
  panel-row-hover:
    backgroundColor: "{colors.surface0}"
  button-primary:
    backgroundColor: "{colors.blue}"
    textColor: "{colors.crust}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "32px"
    padding: "0 14px"
  button-primary-hover:
    backgroundColor: "{colors.lavender}"
  button-secondary:
    backgroundColor: "{colors.surface0}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "32px"
    padding: "0 14px"
  button-secondary-hover:
    backgroundColor: "{colors.surface1}"
  input-field:
    backgroundColor: "{colors.surface0}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    height: "28px"
    padding: "0 8px"
  slider-track:
    backgroundColor: "{colors.surface0}"
    rounded: "{rounded.xs}"
    height: "6px"
  slider-fill:
    backgroundColor: "{colors.blue}"
    rounded: "{rounded.xs}"
  tooltip:
    backgroundColor: "{colors.mantle}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "5px 8px"
---

# Design System: Quickshell (atlas)

## Overview

**Creative North Star: "The Cockpit and the Window"**

The shell has two registers. **The Cockpit** is where the work happens: the 24px bar, its popups, the OSD, notifications, the polkit dialog and Pass quick access. It is a dense, quiet instrument strip. Everything sits on near-black tonal layers, type runs 11–14px, rows line up on icon columns, and nothing is coloured unless the colour reports something. **The Window** is for arriving and leaving: the lock screen, the greeter and the wallpaper picker. They go full-bleed over the aerial wallpaper and its video, with a 300px clock and slow, rising reveals. The Cockpit is felt rather than looked at; the Window is meant to be looked at.

Both registers use the same Catppuccin Mocha palette, Inter, and the same flat, tonal way of building depth. What changes between them is scale and pacing, not materials. Inside the Cockpit, density is a feature. Popups are a fixed 220–560px wide, the controls you use most sit one click from the bar, and resting states stay neutral, so a single green, peach or red glyph reads straight away.

Rejected outright: translucent glass on every surface, gamer RGB and neon glows, big-tile dashboards, and imitating macOS chrome. The aerial wallpapers are content, not a licence to borrow macOS UI.

**Key Characteristics:**
- Quiet, dense, precise in the Cockpit; cinematic only at the edges (lock, greeter, wallpaper picker).
- Depth comes from tone (crust → mantle → base → surface0) plus a 1px border; shadow only on free-floating windows.
- Colour means state. Idle glyphs are overlay0; accents mark on, active, attention or error.
- Controls are quiet until touched: transparent at rest, surface0 on hover, an accent tint when active or armed.
- One easing family (OutCubic). Short state changes, long reveals.

## Colors

Catppuccin Mocha, used as-is (`config/common/Theme.qml`, matching the system theme in `lib/theme`). The neutral ramp does the structural work, and the pastel accents each carry one meaning.

### Primary
- **Blue** (`blue`): focus and primary action. Focus borders on inputs, the primary dialog button, the default slider fill and volume, the selected item in Pass and the wallpaper picker, links in notifications.
- **Lavender** (`lavender`): blue's softer sibling. Primary-button hover in Pass, calendar headings and selection, audio mixer streams.

### Secondary
- **Pink** (`pink`): "you are here". The focused monitor's active workspace, today in the calendar, the OSD, the media card when there's no cover art to take an accent from.

### Tertiary
- **Green** (`green`): on, connected, success. Enabled services in the network panel, active list rows (the default `ListRow` accent), unlocking, the confirm button, a successful copy.
- **Peach** (`peach`): on and worth noticing. Caffeine on, night light on, unread notifications, Do Not Disturb active.
- **Yellow** (`yellow`): brightness, and caution (battery in its middle range, the lock's "Caps Lock is on" notice).
- **Red** (`red`): error, destructive, critical. Wrong password, critical notification border (60% alpha), recording in the privacy indicators, the cancel cross, Shut down.
- **Mauve, Teal, Sky, Sapphire** (`mauve`, `teal`, `sky`, `sapphire`): categorical only. System-stat series, network categories, calendar sources (Sonarr sapphire, Radarr yellow, other sources mauve). They never mean state.
- **Power menu exception:** each action that needs a second click has its own hue, shown on its glyph, label and tint while it's armed (Log out yellow, Reboot peach, Shut down red, Restart into Windows sapphire, Open in a VM teal). At rest every glyph is overlay0, like any other row. Inside that menu the hues tell armed actions apart; they don't report state.

### Neutral
- **Crust** (`crust`): the bar, full-screen backdrops (lock, picker, greeter) and the scrim over a blurred wallpaper (18–42% on the lock, 40% in the picker). Also the label colour on a filled blue button.
- **Mantle** (`mantle`): every popup and floating surface: panels, menus, tooltips, the OSD, dialogs, notification popups.
- **Base** (`base`): inset sections inside a popup (mixer block, identity block, Pass detail, non-floating notification cards in the centre).
- **Surface0** (`surface0`): hover fill, 1px popup borders, slider and progress tracks, inputs, rules between sections, secondary buttons.
- **Surface1** (`surface1`): the bar's separators, hover on something already sitting on surface0.
- **Surface2** (`surface2`): inactive workspaces, text selection.
- **Overlay0** (`overlay0`): idle or muted glyphs, chevrons, disabled accents.
- **Subtext0** (`subtext0`): secondary text: sublabels, values, timestamps, section headings like "Windows".
- **Subtext1** (`subtext1`): small titles that should sit just below primary: slider labels, back-button titles, password prompts.
- **Text** (`text`): primary text and the bar's readouts.

### Named Rules
**The Colour Is a Readout Rule.** An accent appears only when it reports something (on, active, attention, error, here). Idle is overlay0. If you can't say what a coloured glyph is reporting, it should be neutral.

**The One Meaning Rule.** Each accent keeps its single role across every surface. Green never warns, peach never confirms, and the categorical hues never stand in for state.

**The Tint, Don't Fill Rule.** An active or armed row gets its accent at 10% alpha behind accent-coloured text and glyph (15% for hover on the media card's accent buttons). A solid accent fill is only for the one primary button in a dialog.

## Typography

**Display Font:** Inter Display (the lock and greeter clock only)
**Body Font:** Inter
**Glyph Font:** Symbols Nerd Font (icons); Noto Color Emoji where a row shows a flag or emoji

**Character:** One family at two optical sizes. In the Cockpit, Inter is small and set by size and weight alone, never by case or tracking tricks. In the Window, Inter Display at 300px with tight tracking makes the clock the subject of the screen.

### Hierarchy
- **Display** (Inter Display, 500, `300px × s`, −0.04em, `case` feature so the colon centres on the digits): the lock and greeter clock. `s = max(0.75, screenHeight / 1080)`. The ink is pulled onto the margin to make up for the digits' side bearing.
- **Headline** (500, `26px × s`): the lock's date and sunrise/sunset line, and other Window-register lines (19–22px × s in the lock's today panel).
- **Title** (bold, 13px): panel row titles, notification and card titles, the calendar month.
- **Body (bar)** (400, 14px, `Theme.fontSize`): everything in the bar itself.
- **Body** (400, 12px): popup content, list rows, buttons, inputs, tooltips.
- **Label** (400, 11px): sublabels, values, timestamps, section headings.
- **Icon** (Symbols Nerd Font, 16px default; 14px inside rows and buttons; panel-row toggles keep the 16px glyph in a fixed 20px column).

### Named Rules
**The Three Steps Rule.** Popup text uses 13 bold / 12 / 11 and nothing else. Hierarchy within a popup comes from those steps plus the text → subtext1 → subtext0 colour ramp, not from new sizes.

**The Scaled Window Rule.** Window-register sizes are always written as `Math.round(n × s)` against a 1080px reference height, never as fixed px.

## Layout

The bar is one 24px row per screen at the top edge (`Theme.barAtTop`). It has a left cluster (workspaces, window title capped at 400px), a centred now-playing item, and a right cluster of status items with 10px margins and spacing. 1px × 14px surface1 rules in 9px-wide slots split the right cluster into groups: privacy | tray | stats | caffeine + network | date + time | notifications | power. Separators hide when the item they separate is empty.

Popups anchor to their bar item and open away from the bar edge with an 8px gap (6px for tooltips). Widths are fixed per surface: power menu 220, privacy 260, OSD 300, network 320, calendar 350, polkit and notification popups 420, notification centre 440, Pass 560. Inner padding is 12px. Rows pad 8px vertically (10px for panel rows) and 12px horizontally. Glyph columns are fixed (16px, 20px for emoji, 28px in slider rows) so labels line up down a list. Spacing comes only from 2 / 4 / 6 / 8 / 10 / 12; 24px is reserved for the room around a floating window's shadow.

Window-register surfaces are full-screen layer surfaces. The lock pins the clock bottom-left on an 80px × s margin, with side panels for today's events and power. The wallpaper picker is a centred carousel over the blurred current picture.

## Elevation & Depth

Flat by tone. Layers step crust (bar, backdrops) → mantle (popups) → base (inset sections) → surface0 (hover, controls), and every popup carries a 1px surface0 border, so edges read without shadow. Only windows that float free of the bar get a drop shadow: the OSD, polkit dialog and Pass quick access. Blur is reserved for full-screen backdrops (the lock's wallpaper when engaged, the picker's backdrop) and is always followed by a crust scrim.

### Shadow Vocabulary
- **Float** (MultiEffect: black, opacity 0.35, blur 1.0, vertical offset 6px on the OSD and 8px on dialogs, with 24px window padding around the card): free-floating windows only.

### Named Rules
**The Anchored Stays Flat Rule.** Anything attached to the bar (panels, menus, tooltips, notification popups) has no shadow. A shadow means the window floats on its own.

**The Blur Is Backdrop Rule.** Blur never sits behind a panel's content. It only softens a full-screen picture so type can sit on it.

## Shapes

Soft, consistent rounding that steps down as surfaces nest: 12px for popups and floating cards, 10px for the tray menu and media card, 8px for inset sections, panel rows, dialog buttons and non-floating cards, 6px for list rows, inputs, small buttons and tooltips, 3px for slider tracks. Circles (`width / 2`) are for progress rings, avatars and the lock's power buttons. Inner radii are always smaller than their container's. Strokes are 1px only: popup borders, focus rings, the calendar's selected day.

## Components

### Buttons
Quiet until touched.
- **Shape:** gently rounded (8px in dialogs; 6px for 28px icon buttons).
- **Primary:** blue fill with a crust label, 32px tall, at least 88px wide, 12px label. Hover lifts toward lavender (Pass) or 10% lighter blue (polkit). One per dialog.
- **Secondary:** surface0 fill with a text label; hover surface1.
- **Icon buttons:** 28px square on surface0, with the glyph in its semantic accent (green check, red cross). Hover surface1.
- **Disabled:** 50% opacity, faded over 150ms.

### Cards / Containers
- **Corner Style:** 12px for popups and floating cards; 8px for inset sections.
- **Background:** mantle for the popup; base for the sections inside it.
- **Shadow Strategy:** none when anchored; Float when free (see Elevation & Depth).
- **Border:** 1px surface0; 60% red on a critical notification.
- **Internal Padding:** 12px (popup), 8px (inset section).

### Inputs / Fields
- **Style:** surface0 fill, 6px radius, 28px tall, 8px side padding, 12px text, surface2 selection. Polkit's larger field sits on base at 8px.
- **Focus:** a 1px border appears in blue; there is no border at rest.
- **Error:** the border turns red over 150ms, and the polkit card shakes horizontally on a wrong password.

### Lists and Rows
- **List row** (`ListRow`, used for networks, VPN countries, devices and power actions): transparent at rest, surface0 on hover. When active or armed it takes an accent tint at 10%, and its glyph and label take the accent. Layout is glyph column, label (12px, elides), sublabel (11px subtext0).
- **Panel row** (`PanelRow`, the network panel's main rows): a 13px bold title over an 11px subtext0 sublabel. Its leading glyph is a separate toggle target (hover surface1), and the rest of the row opens the sub-view, marked with an overlay0 chevron.
- **Back row** (`BackButton`): chevron-left plus a 12px bold subtext1 title, heading every sub-view.
- **Two-click confirm:** power actions marked `confirm` arm on the first click (the row tints in that action's hue and the label becomes "Click again to …") and run on the second.

### Sliders
- **Track:** 6px surface0, 3px radius; the fill is in the row's accent (blue by default, yellow for brightness, lavender for app streams). Click, drag, or wheel in 5% steps.
- **Slider row:** a 28px glyph column (an app icon replaces the glyph), an optional 80px subtext1 label, then the track, a 38px right-aligned 11px value, and a 22px chevron slot. Only expandable rows draw the chevron, but every row keeps the slot, so tracks and values line up down the panel.

### Navigation (Workspaces)
Glyphs on 10px spacing. Inactive workspaces are surface2. The active one is pink while its monitor has focus, and subtext0 when it doesn't. The hit area extends 5px into the gaps.

### Tooltip
Mantle with a 1px surface0 border, 6px radius, 12px text, appearing after a 400ms hover delay. It is a popup because the 24px bar window can't hold one.

### OSD (signature)
A 300px floating mantle card at the bottom of the focused screen with the Float shadow. Shows the glyph, a progress bar and a value. Accent is blue for volume, yellow for brightness, overlay0 when muted. Fades in on creation and reuses its window for later shows.

### Lock / Greeter (signature)
The Window register. The aerial video plays over its still, blurring (up to 0.7 × 64) and desaturating slightly while the prompt is engaged, under a crust scrim that rises from 18% to 42%. The display clock sits bottom-left. Panels rise 28px and fade in over 650ms OutCubic with staggered delays (`Reveal`), and sink out over 360ms InCubic on unlock.

## Do's and Don'ts

### Do:
- **Do** take every colour, font and size from `Theme` (`qs.common`) and the scales above. No new hex values, and no sizes outside 11 / 12 / 13 / 14 in the Cockpit.
- **Do** keep resting states neutral (overlay0 glyphs, transparent rows) and let accents report state with the roles in Colors.
- **Do** build depth with crust → mantle → base → surface0 plus a 1px surface0 border; add the Float shadow only to windows that aren't anchored to the bar.
- **Do** animate state changes in 140–220ms with `Easing.OutCubic`, and Window-register reveals in about 650ms in / 360ms out.
- **Do** scale Window-register measurements with `s = max(0.75, height / 1080)`.
- **Do** keep icon columns fixed-width so labels line up down a list.

### Don't:
- **Don't** put translucent, blurred glass behind panels or bar content; blur is for full-screen backdrops only.
- **Don't** add glows, gradients, neon or animated accent colour (no gamer RGB).
- **Don't** build big-tile dashboards or oversized toggle cards; controls are rows in a list.
- **Don't** imitate macOS chrome (traffic lights, menu-bar styling); the aerial wallpapers are the only borrowing.
- **Don't** use a categorical hue (mauve, teal, sky, sapphire) to signal state, or give an accent a second meaning.
- **Don't** add a shadow to anchored popups, or a solid accent fill to anything but a dialog's one primary button.
