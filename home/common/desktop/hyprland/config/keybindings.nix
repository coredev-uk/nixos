{
  browser,
  lock,
  menu,
  mod,
  pkgs,
  terminal,
  wallpaper,
  ...
}:
{
  bind = [
    # Media Keys
    ", XF86AudioMute, exec, ${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle"
    ", XF86AudioPlay, exec, ${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"
    ", XF86AudioPause, exec,  ${pkgs.swayosd}/bin/swayosd-client --playerctl play-pause"
    ", XF86AudioNext, exec,  ${pkgs.swayosd}/bin/swayosd-client --playerctl next"
    ", XF86AudioPrev, exec, ${pkgs.swayosd}/bin/swayosd-client --playerctl previous"

    # Main Apps
    "${mod}, L, exec, ${lock}"
    "${mod}, B, exec, ${browser}"
    "${mod}, Return, exec, ${terminal}"
    "${mod}, Space, exec, ${menu}"
    "${mod} SHIFT, P, exec, ${wallpaper}/bin/get-wallpaper --session=hyprland"

    # WM Controls
    "${mod}, R, exec, hyprctl reload"
    "${mod} SHIFT, Q, exec, hyprctl dispatch exit"

    # Window Management
    "${mod}, Q, killactive"
    "${mod} SHIFT, Space, togglefloating"
    "${mod}, P, pseudo" # dwindle
    "${mod}, S, togglesplit" # dwindle
    "${mod}, F, fullscreen"

    # Focus
    "${mod}, left, movefocus, l"
    "${mod}, right, movefocus, r"
    "${mod}, up, movefocus, u"
    "${mod}, down, movefocus, d"

    # Resize
    "${mod} CTRL, left, resizeactive, -20 0"
    "${mod} CTRL, right, resizeactive, 20 0"
    "${mod} CTRL, up, resizeactive, 0 -20"
    "${mod} CTRL, down, resizeactive, 0 20"

    # Tabbed
    "${mod}, w, togglegroup"
    "${mod}, tab, changegroupactive"

    # Mouse Movement
    "${mod}, mouse_down, workspace, e+1" # Scroll-Up
    "${mod}, mouse_up, workspace, e-1" # Scroll-Down
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
          "${mod}, code:1${toString i}, workspace, ${toString ws}"
          "${mod} SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]
      ) 10
    )
  );

  bindr = [
    # Screenshot
    "${mod}, Print, exec, ${pkgs.hyprshot}/bin/hyprshot -m region --raw | ${pkgs.satty}/bin/satty --fullscreen --early-exit -f - --copy-command ${pkgs.wl-clipboard-rs}/bin/wl-copy"
    ", Print, exec, ${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only"
  ];

  bindm = [
    "${mod}, mouse:272, movewindow" # Left-Click
    "${mod}, mouse:273, resizewindow" # Right-Click
  ];

  # MultiMedia: Volume Up/Down
  binde = [
    ", XF86AudioRaiseVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume +5"
  ];
  bindl = [
    ", XF86AudioLowerVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume -5%"
    ", XF86MonBrightnessDown, exec, hyprctl hyprsunset gamma -10"
    ", XF86MonBrightnessUp, exec, hyprctl hyprsunset gamma +10"
  ];
}
