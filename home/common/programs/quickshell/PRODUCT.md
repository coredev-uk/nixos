# Product

<!-- impeccable:product-schema 1 -->

## Platform

desktop

## Users

One user: paul, on `atlas` (NixOS desktop, Hyprland on Wayland, NVIDIA GPU, two 1440p 120 Hz screens). The shell is his everyday desktop. No other hosts or people use it. `poseidon` runs macOS, and `athena` runs Windows.

## Product Purpose

A single Quickshell (Qt 6 / QML) config that provides the whole desktop shell around Hyprland. It replaces the separate bar, notification daemon, OSD, polkit agent, lock screen and greeter that would otherwise be needed. Success means daily controls are reachable from the shell without opening an app, and the surfaces that guard the session never fail open.

## Positioning

The shell is built for one machine and one person, so it can use atlas specifics directly: its screens, its peripherals, Proton Pass, iCloud, Sonarr/Radarr, Windows dual boot and the VFIO VM. It doesn't need the portability abstractions a published shell would. One QML tree runs as three separate instances so that a failure in one can't take down another:

- **Bar** (`config/shell.qml`): home-manager `programs.quickshell`, a systemd user service that restarts on switch.
- **Lock** (`config/lockscreen.qml`): its own one-shot instance (`quickshell-lock`, started by hypridle's `lock_cmd`), so a bar restart can't take the lock down.
- **Greeter** (`config/greeter.qml`): runs under greetd as the `greeter` user and reuses the lock screen's faces (`hosts/common/desktop/greeter.nix`).

## Operating Context

- Entry points: always-on bar per screen; Hyprland keybinds call the bar over IPC: media/volume/brightness keys → `osd`, Super+Shift+P → wallpaper picker, Ctrl+Shift+Space → Pass quick access, Super+L → lock.
- Bar contents: workspaces, window title, now playing (opens its media card), privacy indicators, tray, system stats, caffeine, low peripheral battery, network (the control panel), date/calendar, clock, notification centre, power menu.
- Panels and views: the control panel behind the network glyph (volume named by its output with outputs including AirPlay 2 and the per-app mixer under it, brightness, night light via hyprsunset with a per-session temperature, Ethernet, WiFi, VPN via the ProtonVPN CLI, connection details, Bluetooth, Cast screen to Chromecast via GNOME Network Displays, device batteries from upower, openrazer and headsetcontrol, media), calendar (iCloud CalDAV and Sonarr/Radarr from `~/.config/quickshell/calendars.json`, kept out of git), power menu (including restart to Windows and the Windows VM).
- On air: while an app captures the screen, Pass quick access, notification popups and the lock's today panel keep personal detail off it.
- Lock and greeter: wallpaper still with its aerial video behind it (macOS aerial clips, `home/common/programs/hypr/paper.nix`), the clock, today's events, and the next sunrise or sunset from wlsunset's location.

## Capabilities and Constraints

- Stack: Quickshell on Qt 6 / QML; Nix (home-manager module `default.nix`, NixOS modules under `hosts/`). Helper scripts in `scripts/` are wrapped with `writeShellApplication`.
- Some runtime tools come from the user's or host's PATH, not from Nix inputs: `pass-cli` shares the user's signed-in session, and `headsetcontrol` comes with its udev rules from `hosts/atlas/extra.nix`.
- The config is a read-only store symlink, and fonts are read only at startup, so changes take effect only when the service restarts on switch.
- The lock refuses to start without `/etc/pam.d/quickshell-lock`. Authentication is password only, with no U2F prompt. Hyprland's `allow_session_lock_restore` lets `quickshell-lock` take a session over again from a TTY if the lock crashes.
- The greeter runs as `greeter` and can't read the user's home, so the wallpaper is copied to a system path. Location comes from the wlsunset module, read as-is.
- On NVIDIA, the lock's video depends on a patched Qt Multimedia and nvidia-vaapi-driver from master (`default.nix`). The cost was measured: roughly 75% → 45% of a core for two 1440p120 players.
- Terminology: "control panel", "on air", "Pass quick access", "notification centre", "power menu", "OSD", "Horizon" lock screen.
- Undecided: none recorded.

## Brand Commitments

None. This is a personal tool.

## Evidence on Hand

Not applicable: there is no external audience. Don't invent usage data or claims.

## Product Principles

1. **Reach, don't switch.** If a control is used daily, it lives in the shell. Opening an app to change audio, network, casting, calendar, a password or power state counts as a gap.
2. **Trust surfaces fail closed.** Correctness beats features on the lock, greeter, polkit dialog and Pass quick access. They must never fail open, hang, or leave secrets on screen or in the clipboard longer than intended.
3. **Cost is a feature.** CPU and GPU use is a design constraint, measured rather than assumed, especially for always-on parts and video.
4. **One machine, no hedging.** Build for atlas as it is; hardware- and account-specific behaviour is fine, and portability layers are not wanted.
