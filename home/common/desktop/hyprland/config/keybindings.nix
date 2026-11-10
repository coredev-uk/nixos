{
  browser,
  lock,
  menu,
  mod,
  pkgs,
  terminal,
  lua,
  luaCall,
  ...
}:
let
  bind =
    keys: dispatcher:
    luaCall [
      keys
      (lua dispatcher)
    ];

  bindWith =
    keys: dispatcher: flags:
    luaCall [
      keys
      (lua dispatcher)
      flags
    ];

  exec = command: "hl.dsp.exec_cmd(${builtins.toJSON command})";
  focus = direction: "hl.dsp.focus({ direction = ${builtins.toJSON direction} })";
  moveWindow = direction: "hl.dsp.window.move({ direction = ${builtins.toJSON direction} })";
  workspace = workspace: "hl.dsp.focus({ workspace = ${builtins.toJSON workspace} })";
  moveToWorkspace = workspace: "hl.dsp.window.move({ workspace = ${builtins.toJSON workspace} })";
  resize = x: y: "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
in
{
  bind = [
    # Media Keys (on-screen display: home/common/programs/quickshell/config/modules/Osd.qml)
    (bindWith "XF86AudioMicMute" (exec "quickshell ipc -c bar call osd micMute") { locked = true; })
    (bindWith "XF86AudioMute" (exec "quickshell ipc -c bar call osd mute") { locked = true; })
    (bindWith "XF86AudioPlay" (exec "quickshell ipc -c bar call osd media play-pause") {
      locked = true;
    })
    (bindWith "XF86AudioPause" (exec "quickshell ipc -c bar call osd media play-pause") {
      locked = true;
    })
    (bindWith "XF86AudioNext" (exec "quickshell ipc -c bar call osd media next") { locked = true; })
    (bindWith "XF86AudioPrev" (exec "quickshell ipc -c bar call osd media previous") { locked = true; })

    # Main Apps
    (bind "${mod} + L" (exec lock))
    (bind "${mod} + B" (exec "uwsm app -- ${browser}"))
    (bind "${mod} + Return" (exec terminal))
    (bind "${mod} + Space" (exec menu))
    # Wallpaper picker (home/common/programs/quickshell/config/modules/WallpaperPicker.qml)
    (bind "${mod} + SHIFT + P" (exec "quickshell ipc -c bar call wallpapers toggle"))
    # Proton Pass quick access (home/common/programs/quickshell/config/modules/PassQuickAccess.qml)
    (bind "CTRL + SHIFT + Space" (exec "quickshell ipc -c bar call pass toggle"))
    # Screen recording on the focused monitor (home/common/programs/quickshell/config/services/Recorder.qml)
    (bind "${mod} + SHIFT + R" (exec "quickshell ipc -c bar call recorder toggle"))
    # Instant replay (home/common/programs/quickshell/config/services/Replay.qml): save the last
    # 30 seconds, or all of the buffer with Ctrl
    (bind "${mod} + SHIFT + C" (exec "quickshell ipc -c bar call replay clip 30"))
    (bind "${mod} + CTRL + SHIFT + C" (exec "quickshell ipc -c bar call replay save"))

    # WM Controls
    (bind "${mod} + R" (exec "hyprctl reload"))
    (bind "${mod} + SHIFT + Q" (exec "uwsm stop"))

    # Window Management
    (bind "${mod} + Q" "hl.dsp.window.close()")
    (bind "${mod} + SHIFT + Space" "hl.dsp.window.float()")
    (bind "${mod} + P" "hl.dsp.window.pseudo()") # dwindle
    (bind "${mod} + J" "hl.dsp.layout(\"togglesplit\")") # dwindle
    (bind "${mod} + F" "hl.dsp.window.fullscreen()")

    # Focus
    (bind "${mod} + left" (focus "l"))
    (bind "${mod} + right" (focus "r"))
    (bind "${mod} + up" (focus "u"))
    (bind "${mod} + down" (focus "d"))

    # Move the window in a direction, across monitors at the edge
    (bind "${mod} + SHIFT + left" (moveWindow "l"))
    (bind "${mod} + SHIFT + right" (moveWindow "r"))
    (bind "${mod} + SHIFT + up" (moveWindow "u"))
    (bind "${mod} + SHIFT + down" (moveWindow "d"))

    # Resize
    (bind "${mod} + CTRL + left" (resize (-20) 0))
    (bind "${mod} + CTRL + right" (resize 20 0))
    (bind "${mod} + CTRL + up" (resize 0 (-20)))
    (bind "${mod} + CTRL + down" (resize 0 20))

    # Tabbed
    (bind "${mod} + w" "hl.dsp.group.toggle()")
    (bind "${mod} + tab" "hl.dsp.group.next()")

    # Mouse Movement
    (bind "${mod} + mouse_down" (workspace "e+1")) # Scroll-Up
    (bind "${mod} + mouse_up" (workspace "e-1")) # Scroll-Down
  ]
  ++ (
    # workspaces
    # binds ${mod} + [shift +] {1..9} to [move to] workspace {1..9}
    builtins.concatLists (
      builtins.genList (
        i:
        let
          ws = i + 1;
        in
        [
          (bind "${mod} + code:1${toString i}" (workspace ws))
          (bind "${mod} + SHIFT + code:1${toString i}" (moveToWorkspace ws))
        ]
      ) 10
    )
  )
  ++ [
    # Screenshot: Super+Print goes straight to satty; Print copies the area and shows the
    # popup (home/common/programs/quickshell/config/modules/ScreenshotPopup.qml, scripts/screenshot.sh)
    (bindWith "${mod} + Print"
      (exec "${pkgs.grimblast}/bin/grimblast save area - | ${pkgs.satty}/bin/satty --fullscreen --early-exit -f - --copy-command ${pkgs.wl-clipboard}/bin/wl-copy")
      { release = true; }
    )
    (bindWith "Print" (exec "quickshell-screenshot") {
      release = true;
    })

    (bindWith "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; }) # Left-Click
    (bindWith "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; }) # Right-Click

    # MultiMedia: Volume and brightness repeat while held and work over the lock screen
    (bindWith "XF86AudioRaiseVolume" (exec "quickshell ipc -c bar call osd volume +5") {
      repeating = true;
      locked = true;
    })
    (bindWith "XF86AudioLowerVolume" (exec "quickshell ipc -c bar call osd volume -5") {
      repeating = true;
      locked = true;
    })
    (bindWith "XF86MonBrightnessDown" (exec "quickshell ipc -c bar call osd brightness -10") {
      repeating = true;
      locked = true;
    })
    (bindWith "XF86MonBrightnessUp" (exec "quickshell ipc -c bar call osd brightness +10") {
      repeating = true;
      locked = true;
    })
  ];
}
