{
  browser,
  lock,
  menu,
  mod,
  pkgs,
  terminal,
  wallpaper,
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
    # Media Keys
    (bind "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")) # ${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle"
    (bind "XF86AudioMute" (exec "${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle"))
    (bind "XF86AudioPlay" (exec "${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"))
    (bind "XF86AudioPause" (exec "${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"))
    (bind "XF86AudioNext" (exec "${pkgs.swayosd}/bin/swayosd-client --playerctl next"))
    (bind "XF86AudioPrev" (exec "${pkgs.swayosd}/bin/swayosd-client --playerctl previous"))

    # Main Apps
    (bind "${mod} + L" (exec lock))
    (bind "${mod} + B" (exec browser))
    (bind "${mod} + Return" (exec terminal))
    (bind "${mod} + Space" (exec menu))
    (bind "${mod} + SHIFT + P" (
      exec ''hyprctl hyprpaper wallpaper " , $(${wallpaper}/bin/get-wallpaper), cover"''
    ))
    (bind "CTRL + SHIFT + Space" (exec "${pkgs._1password-gui}/bin/1password --quick-access"))

    # WM Controls
    (bind "${mod} + R" (exec "hyprctl reload"))
    (bind "${mod} + SHIFT + Q" (exec "${pkgs.uwsm}/bin/uwsm stop"))

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
      (exec "${pkgs.hyprshot}/bin/hyprshot -m region --raw | ${pkgs.satty}/bin/satty --fullscreen --early-exit -f - --copy-command ${pkgs.wl-clipboard-rs}/bin/wl-copy")
      { release = true; }
    )
    (bindWith "Print" (exec "${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only") {
      release = true;
    })

    (bindWith "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; }) # Left-Click
    (bindWith "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; }) # Right-Click

    # MultiMedia: Volume Up/Down
    (bindWith "XF86AudioRaiseVolume" (exec "${pkgs.swayosd}/bin/swayosd-client --output-volume +5") {
      repeating = true;
    })
    (bindWith "XF86MonBrightnessDown" (exec "set-brightness-all 10%-") { repeating = true; })
    (bindWith "XF86MonBrightnessUp" (exec "set-brightness-all 10%+") { repeating = true; })
    (bindWith "XF86AudioLowerVolume" (exec "${pkgs.swayosd}/bin/swayosd-client --output-volume -5") {
      locked = true;
    })
  ];
}
