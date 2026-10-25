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
  workspace = workspace: "hl.dsp.focus({ workspace = ${builtins.toJSON workspace} })";
  moveToWorkspace = workspace: "hl.dsp.window.move({ workspace = ${builtins.toJSON workspace} })";
  resize = x: y: "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
in
{
  bind = [
    # Media Keys (on-screen display: home/common/programs/quickshell/config/modules/Osd.qml)
    (bind "XF86AudioMicMute" (exec "quickshell ipc -c bar call osd micMute"))
    (bind "XF86AudioMute" (exec "quickshell ipc -c bar call osd mute"))
    (bind "XF86AudioPlay" (exec "quickshell ipc -c bar call osd media play-pause"))
    (bind "XF86AudioPause" (exec "quickshell ipc -c bar call osd media play-pause"))
    (bind "XF86AudioNext" (exec "quickshell ipc -c bar call osd media next"))
    (bind "XF86AudioPrev" (exec "quickshell ipc -c bar call osd media previous"))

    # Main Apps
    (bind "${mod} + L" (exec lock))
    (bind "${mod} + B" (exec browser))
    (bind "${mod} + Return" (exec terminal))
    (bind "${mod} + Space" (exec menu))
    # Wallpaper picker (home/common/programs/quickshell/config/modules/WallpaperPicker.qml)
    (bind "${mod} + SHIFT + P" (exec "quickshell ipc -c bar call wallpapers toggle"))
    (bind "CTRL + SHIFT + Space" (exec "1password --quick-access"))

    # WM Controls
    (bind "${mod} + R" (exec "hyprctl reload"))
    (bind "${mod} + SHIFT + Q" (exec "uwsm stop"))

    # Window Management
    (bind "${mod} + Q" "hl.dsp.window.close()")
    (bind "${mod} + SHIFT + Space" "hl.dsp.window.float()")
    (bind "${mod} + P" "hl.dsp.window.pseudo()") # dwindle
    # "${mod}, S, togglesplit" # dwindle
    (bind "${mod} + F" "hl.dsp.window.fullscreen()")

    # Focus
    (bind "${mod} + left" (focus "l"))
    (bind "${mod} + right" (focus "r"))
    (bind "${mod} + up" (focus "u"))
    (bind "${mod} + down" (focus "d"))

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
    # Screenshot
    (bindWith "${mod} + Print"
      (exec "${pkgs.grimblast}/bin/grimblast save area - | ${pkgs.satty}/bin/satty --fullscreen --early-exit -f - --copy-command ${pkgs.wl-clipboard}/bin/wl-copy")
      { release = true; }
    )
    (bindWith "Print" (exec "${pkgs.grimblast}/bin/grimblast copy area") {
      release = true;
    })

    (bindWith "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; }) # Left-Click
    (bindWith "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; }) # Right-Click

    # MultiMedia: Volume Up/Down
    (bindWith "XF86AudioRaiseVolume" (exec "quickshell ipc -c bar call osd volume +5") {
      repeating = true;
    })
    (bindWith "XF86MonBrightnessDown" (exec "quickshell ipc -c bar call osd brightness -10") {
      repeating = true;
    })
    (bindWith "XF86MonBrightnessUp" (exec "quickshell ipc -c bar call osd brightness +10") {
      repeating = true;
    })
    (bindWith "XF86AudioLowerVolume" (exec "quickshell ipc -c bar call osd volume -5") {
      locked = true;
    })
  ];
}
