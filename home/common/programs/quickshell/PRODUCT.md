# Product

<!-- impeccable:product-schema 1 -->

## Platform

desktop

## Users

One user: paul, on `atlas` (NixOS desktop, Hyprland on Wayland, NVIDIA GPU, two 1440p 120 Hz screens). The shell is his everyday desktop. No other hosts or people use it. `poseidon` runs macOS, and `athena` runs Windows.

## Product Purpose

A single Quickshell (Qt 6 / QML) config that provides the whole desktop shell around Hyprland. It replaces the separate bar, notification daemon, OSD, polkit agent, screen-share picker, lock screen and greeter that would otherwise be needed. Success means daily controls are reachable from the shell without opening an app, and the surfaces that guard the session never fail open.

## Positioning

The shell is built for one machine and one person, so it can use atlas specifics directly: its screens, its peripherals, Proton Pass, iCloud, Sonarr/Radarr, Windows dual boot and the VFIO VM. It doesn't need the portability abstractions a published shell would. One QML tree runs as four separate instances so that a failure in one can't take down another:

- **Bar** (`config/shell.qml`): home-manager `programs.quickshell`, a systemd user service that restarts on switch.
- **Lock** (`config/lockscreen.qml`): its own one-shot instance (`quickshell-lock`, started by hypridle's `lock_cmd`), so a bar restart can't take the lock down.
- **Greeter** (`config/greeter.qml`): runs under greetd as the `greeter` user and reuses the lock screen's faces (`hosts/common/desktop/greeter.nix`).
- **Share picker** (`config/sharepicker.qml`): run by xdg-desktop-portal-hyprland (its `custom_picker_binary`, the `quickshell-share-picker` wrapper writing `~/.config/hypr/xdph.conf`) whenever an app asks to share the screen; shows a still of every screen and window, or a dragged region, and hands the choice back to xdph. Restart `xdg-desktop-portal-hyprland` after changing the wrapper.

## Operating Context

- Entry points: always-on bar per screen; Hyprland keybinds call the bar over IPC: media/volume/brightness keys → `osd`, Super+Shift+P → wallpaper picker, Ctrl+Shift+Space → Pass quick access, Super+L → lock, Super+Shift+R → screen recording (`recorder toggle`), Super+Shift+C → save the instant replay's last 30 seconds (`replay clip 30`), Super+Ctrl+Shift+C → save all of it (`replay save`), Print → `quickshell-screenshot` (select an area, copy it, then a popup with the picture, Edit in satty and Save to the XDG screenshots directory; Super+Print still goes straight to satty).
- Bar contents: workspaces, window title, now playing (opens the now-playing strip: artwork, controls and time, with Sona its timed lyrics from `sona lyrics --follow --json` and `sona lyrics --json`, run only while the strip is out, over a level trace of the player's PipeWire stream, and a seek track along its floor), privacy indicators, tray, system stats, capture (the capture menu: screenshot, recording, instant replay; the recording time while recording), caffeine, low peripheral battery, network (the control panel), date/calendar, clock, notification centre, power menu.
- Claude week (the control panel's Claude section, for day-to-day tracking of the plan's weekly limit against how much of the week has gone): `quickshell-claude-usage` reads the usage endpoint behind claude.ai's settings every 5 minutes, signed in with omp's Anthropic OAuth credential from `~/.omp/agent/agent.db`, read only: omp rotates the refresh token when it refreshes, so the shell never refreshes it and, while the access token has expired, shows the last reading with its time until omp next runs. The week's chart joins the shell's own readings (`~/.local/state/quickshell-claude-usage`) with omp's `usage_history`. The endpoint rate-limits, so a read on showing the section is skipped within two minutes of the last.
- Panels and views: the control panel behind the network glyph, one section at a time from a rail down its left edge, at a fixed height (Sound: output volume named by its output and input volume, the outputs including AirPlay 2, the per-app mixer; Display: brightness, night light via hyprsunset with a per-session temperature, Cast screen to Chromecast via GNOME Network Displays; Network: Ethernet, WiFi, VPN via the ProtonVPN CLI, connection details; Devices: Bluetooth and its devices, peripheral batteries from upower, openrazer and headsetcontrol; Nix: the lock updates waiting to land (BOT Cecil's nightly trials, one draft pull request per flake input, and the pull request that lands the passing ones together, each with its pending or failed checks and how long it has been failing; a click opens it), main's atlas builds (the Actions workflow behind the binary cache), the cache's size, and this computer's generation, update and reboot state, and any failed systemd units, system or user, listed by name (a click copies the `journalctl` command; the Nix rail glyph turns alert for them, read on the helper's 5-minute cadence), read by `quickshell-nix-status` from GitHub's API, main's `flake.lock`, the cache itself and `systemctl --failed`; Claude: the Claude week, above; under every section, what's playing: cover, track, controls, time and a seek track, on a card tinted from the cover, with Sona's favourite heart through `sona like status|toggle --json`, asked only while it's on screen), calendar (iCloud CalDAV and Sonarr/Radarr from `~/.config/quickshell/calendars.json`, kept out of git), power menu (including restart to Windows and the Windows VM).
- On air: while an app captures the screen or the shell records it, Pass quick access, notification popups, the screenshot popup's picture and the lock's today panel keep personal detail off it. The instant replay buffer is not on air (see below).
- Screen recording: `gpu-screen-recorder` (NVENC) captures the focused monitor at 60 fps with what the default output plays into `~/videos/recordings` (`XDG_RECORDINGS_DIR`, `home/common/shell/xdg.nix`) as a timestamped mp4, started and stopped from Super+Shift+R or the capture menu, both through `services/Recorder.qml`. Saving raises a notification (a click plays the file, "Show in folder" opens it) and a failure raises a critical one with the recorder's reason. Only a whole screen can be recorded, not an area or a window.
- Instant replay (ShadowPlay): armed from the capture menu, `gpu-screen-recorder` keeps the last 5 minutes (`replaySeconds` in `default.nix`, the one constant) of DP-1 and what the default output plays in RAM, in the `quickshell-replay` user unit. Super+Shift+C (or the menu) writes its last 30 seconds and Super+Ctrl+Shift+C all of it to the recordings folder as `replay-<time>.mp4`, notifying like a finished recording; `replay clip SECONDS` takes the recorder's other lengths too (10 s, 1, 5, 10 or 30 min). DP-1 is the primary screen: the 165 Hz one with VRR that games run on, and workspace 1's. Armed or not is kept in the bar's state dir (`replay.json`, like Do Not Disturb) and the bar starts the unit again at login; the unit is a service of its own so the bar's restarts on switch don't empty the buffer, and systemd restarts it if the recorder dies (five failures in five minutes and the bar turns it off and says why). It is not on air: buffering shares nothing and a saved clip is a file made on purpose; the capture glyph is gilt while it is armed. It is never paused: it records the lock screen and keeps going through DPMS, and a recorder that a suspend kills comes back with an empty buffer.
- Lock and greeter: wallpaper still with its aerial video behind it (macOS aerial clips, `home/common/programs/hypr/paper.nix`), the clock, today's events, and the next sunrise or sunset from wlsunset's location.

## Capabilities and Constraints

- Stack: Quickshell on Qt 6 / QML; Nix (home-manager module `default.nix`, NixOS modules under `hosts/`). Helper scripts in `scripts/` are wrapped with `writeShellApplication`.
- Some runtime tools come from the user's or host's PATH, not from Nix inputs: `pass-cli` shares the user's signed-in session, and `headsetcontrol` comes with its udev rules from `hosts/atlas/extra.nix`.
- The config is a read-only store symlink, and fonts are read only at startup, so changes take effect only when the service restarts on switch.
- The lock refuses to start without `/etc/pam.d/quickshell-lock`. Authentication is password only, with no U2F prompt. Hyprland's `allow_session_lock_restore` lets `quickshell-lock` take a session over again from a TTY if the lock crashes.
- Idle locks (hypridle's 5-minute timeout, `quickshell-lock --grace 10`) have a 10-second grace period: any key or pointer input in that window unlocks without the password, and the lock says so top-left over a draining track. Locks from Super+L, the power menu or sleep have none, and the window is measured on the wall clock, so it can't outlast a suspend.
- The greeter runs as `greeter` and can't read the user's home, so the wallpaper and its clip are copied to a system path (`/var/lib/greeter-wallpaper`, by `set-wallpaper` and `wallpaper-video`; the clip is removed when the picture changes and copied back once its replacement exists). Location comes from the wlsunset module, read as-is.
- On NVIDIA, the lock's and greeter's video depends on a patched Qt Multimedia and nvidia-vaapi-driver from master (`video.nix`, imported by both `default.nix` and `hosts/common/desktop/greeter.nix`). The cost was measured: roughly 75% → 45% of a core for two 1440p120 players.
- Recording needs `programs.gpu-screen-recorder` (`hosts/common/desktop/hyprland.nix`): KMS capture runs `gsr-kms-server` with `cap_sys_admin` from that module's wrapper, and the module's package is the one that finds it. `quickshell-record` refuses to start without it (a notification saying to rebuild NixOS) instead of letting the recorder ask for root through polkit. The replay buffer's cost was measured on atlas (1440p60 H.264 at 20 Mbit/s on the RTX 3080, a 60-second buffer): about 28% of NVENC and 8% of one CPU core, with 400 MB resident after a minute; the buffer itself grows 150 MB a minute, so the 5 minutes kept are 750 MB on top of about 270 MB for the recorder.
- The greeter's video never gates login: the clip only loads when its copy exists, the still shows until its first frame and wherever it can't play, it stops when the password is accepted, and a greeter that dies with the clip playing restarts with the still alone.
- sudo asks through the polkit dialog, like Touch ID on macOS (`hosts/common/desktop/sudo-polkit.nix`): a `pam_exec` step before the security key and password runs `pkcheck` for the shell that ran sudo, and the dialog names the full command ("Authentication is needed to run “sudo …”"). Cancelling it falls back to the terminal prompt, as does anything with no graphical session to ask in (SSH, a TTY) and `sudo -n`/`-S`/`-A`. The `local.sudo` action is `auth_self` for the active local session only, so it is never a way around the password.
- The polkit dialog (and so sudo) takes a YubiKey touch before the password (`pam_u2f` on `polkit-1`, `hosts/common/desktop/default.nix`): the field shows the key glyph and "Touch your security key" while it waits, and asks for the password if the key isn't touched or plugged in. Keys are registered in the root-owned `/etc/u2f_mappings` (`pamu2fcfg`), kept out of the repo; polkit's sandboxed helper service is let through to the keys' hidraw devices. The lock screen and the greeter stay password only: a key left in the PC would open them to anyone at the desk, and the greeter's password unlocks GNOME Keyring.
- Terminology: "control panel", "Claude week", "on air", "Pass quick access", "notification centre", "power menu", "OSD", "Horizon" lock screen.
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
