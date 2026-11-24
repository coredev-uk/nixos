{
  browser,
  lock,
  menu,
  mod,
  pkgs,
  terminal,
  lua,
  luaCall,
  zen,
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
    # Media keys (OSD: quickshell Osd.qml)
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

    (bind "${mod} + L" (exec lock))
    # Show the main Zen window parked in special:browser (../default.nix), or park it when focused;
    # otherwise open a new window.
    (bind "${mod} + B" ''
      function()
        local active = hl.get_active_window()
        if active and ${zen.isMain "active"} then
          ${zen.park "active"}
          return
        end
        for _, w in ipairs(hl.get_windows()) do
          if ${zen.isMain "w"} and w.workspace and w.workspace.name == "special:browser" then
            hl.dispatch(hl.dsp.window.move({ window = w, workspace = hl.get_active_workspace().id }))
            hl.dispatch(hl.dsp.focus({ window = w }))
            return
          end
        end
        hl.exec_cmd("uwsm app -- ${browser}")
      end
    '')
    (bind "${mod} + Return" (exec terminal))
    (bind "${mod} + Space" (exec menu))
    (bind "${mod} + SHIFT + P" (exec "quickshell ipc -c bar call wallpapers toggle"))
    (bind "CTRL + SHIFT + Space" (exec "quickshell ipc -c bar call pass toggle"))
    # Runs from login (../default.nix) in the tray; a second launch shows its window
    (bind "CTRL + ALT + Space" (exec "uwsm app -- proton-pass"))
    (bind "${mod} + SHIFT + R" (exec "quickshell ipc -c bar call recorder toggle"))
    # Instant replay (quickshell Replay.qml): last 30 s; with Ctrl, the whole buffer
    (bind "${mod} + SHIFT + C" (exec "quickshell ipc -c bar call replay clip 30"))
    (bind "${mod} + CTRL + SHIFT + C" (exec "quickshell ipc -c bar call replay save"))
    # Proton Mail scratchpad (window-rules.nix): hide with this, closing quits the app; start it if not running
    (bind "${mod} + M" ''
      function()
        for _, w in ipairs(hl.get_windows()) do
          if w.class == "proton-mail" then
            hl.dispatch(hl.dsp.workspace.toggle_special("mail"))
            return
          end
        end
        hl.exec_cmd("uwsm app -- proton-mail")
        local shown = hl.get_active_special_workspace()
        if not (shown and shown.name == "special:mail") then
          hl.dispatch(hl.dsp.workspace.toggle_special("mail"))
        end
      end
    '')

    (bind "${mod} + R" (exec "hyprctl reload"))
    (bind "${mod} + SHIFT + Q" (exec "uwsm stop"))

    # Zen's last main window is parked instead (../default.nix)
    (bind "${mod} + Q" ''
      function()
        local active = hl.get_active_window()
        if active and ${zen.isMain "active"} then
          ${zen.close "active"}
        else
          hl.dispatch(hl.dsp.window.close())
        end
      end
    '')
    (bind "${mod} + SHIFT + Space" "hl.dsp.window.float()")
    (bind "${mod} + P" "hl.dsp.window.pseudo()") # dwindle
    (bind "${mod} + J" "hl.dsp.layout(\"togglesplit\")") # dwindle
    (bind "${mod} + F" "hl.dsp.window.fullscreen()")

    (bind "${mod} + left" (focus "l"))
    (bind "${mod} + right" (focus "r"))
    (bind "${mod} + up" (focus "u"))
    (bind "${mod} + down" (focus "d"))

    (bind "${mod} + SHIFT + left" (moveWindow "l"))
    (bind "${mod} + SHIFT + right" (moveWindow "r"))
    (bind "${mod} + SHIFT + up" (moveWindow "u"))
    (bind "${mod} + SHIFT + down" (moveWindow "d"))

    (bind "${mod} + CTRL + left" (resize (-20) 0))
    (bind "${mod} + CTRL + right" (resize 20 0))
    (bind "${mod} + CTRL + up" (resize 0 (-20)))
    (bind "${mod} + CTRL + down" (resize 0 20))

    (bind "${mod} + w" "hl.dsp.group.toggle()")
    (bind "${mod} + tab" "hl.dsp.group.next()")

    (bind "${mod} + mouse_down" (workspace "e+1"))
    (bind "${mod} + mouse_up" (workspace "e-1"))
  ]
  ++ (builtins.concatLists (
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
  ))
  ++ [
    # Super+Print goes straight to satty; Print copies the area and shows the popup (quickshell ScreenshotPopup.qml)
    (bindWith "${mod} + Print"
      (exec "${pkgs.grimblast}/bin/grimblast save area - | ${pkgs.satty}/bin/satty --fullscreen --early-exit -f - --copy-command ${pkgs.wl-clipboard}/bin/wl-copy")
      { release = true; }
    )
    (bindWith "Print" (exec "quickshell-screenshot") {
      release = true;
    })

    (bindWith "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
    (bindWith "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })

    # Volume/brightness repeat while held and work over the lock screen
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
