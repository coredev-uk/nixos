---
version: 1
slug: "config-shell-qml"
primary_target: "config/shell.qml"
related_targets: ["config/lockscreen.qml","config/greeter.qml","wallpaper/shell.qml"]
---

# Surface brief: Quickshell (atlas), whole shell

Scope: every Quickshell surface (bar, anchored panels, notifications, OSD, polkit, Pass quick access, wallpaper picker, lock, greeter, wallpaper instance), plus Hyprland borders/groupbar and Vicinae following the palette. Mode: Operate (bar and panels); the lock, greeter and picker are its Window-register edges.

Audience and job: one person on atlas, two 2560×1440 screens, all hours in a dark room with the night light warming the screen after sunset. Daily controls one click from the bar; trust surfaces fail closed.

Constraint from the user: nothing may create "a sense of uneasiness in the system". Calm, settled, no jitter, no flashes.

## Direction contract

THESIS: The shell keeps time like Greenwich. It refuses the pastel Catppuccin unixporn bar and the macOS glass menubar; it is a quiet night-navy instrument of the day the wallpaper already follows.

OWN-WORLD: Night-navy ground (#0f1826 bar, #1a2638 plates, #121c2b insets, #2b3b54 1px rules), enamel-cream legends (#ece5d3 and a muted enamel), gilt (#c9a24f) only for "here" and "on" and the one primary button; signal red for errors and recording, verdigris for connected/success. Atkinson Hyperlegible Next everywhere with tabular figures. Plates 10px radius, rows 6px, 32px inset glyph tiles.

STORY: Paul glances up, reads state in under a second, and nothing moved that didn't change. He trusts that gilt means "this is where I am / this is on" and red means something needs him.

FIRST VIEWPORT: 24px navy bar flush to the top edge with a 1px rule; workspaces as numerals, the focused one gilt over a 2px gilt rule; now playing centred; right cluster ends "Wed 28 Oct ─●─ 13:23" with the 120px day arc inline (sunrise/sunset ticks, daylight span brighter, gilt dot at now). Panels hang 8px below as navy plates.

FORM: Meridian (Royal Observatory Greenwich, Shepherd Gate 24-hour clock); grounded list #1, chosen by the user's steer over the rolled Guide Signs. seed:f849ab3a00a1ccd9

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
