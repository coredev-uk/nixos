{
  self,
  lib,
  pkgs,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  shared = import ./shared.nix { inherit lib theme; };
in
{
  # Fonts come from hosts/common/desktop on NixOS; darwin has no desktop module, so install here.
  home.packages = lib.optionals meta.isDarwin [
    theme.fonts.monospace.package
    theme.fonts.iconFont.package
  ];

  # Drop-in for every Ghostty surface scope. zsh in zellij panes ignores SIGTERM and hung shutdown
  # until the 90 s timeout; SIGHUP makes shells exit, the timeout bounds the rest.
  # OOMPolicy=continue: an OOM kill of one process (linker, test binary) must not take down the whole tab.
  # MemoryHigh/Max 35%/40%: a runaway tab is OOM-killed itself, not system-wide (which hit Proton Pass, the SSH agent).
  xdg.configFile."systemd/user/app-ghostty-surface-transient-.scope.d/stop.conf" =
    lib.mkIf (!meta.isDarwin)
      {
        text = ''
          [Scope]
          SendSIGHUP=yes
          TimeoutStopSec=10s
          OOMPolicy=continue
          MemoryHigh=35%
          MemoryMax=40%
        '';
      };

  programs.ghostty = {
    enable = true;

    themes.meridian = shared.meridian;

    package = if meta.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = shared.settings // {
      theme = "meridian";
      confirm-close-surface = false;
      # Alt chords for zellij.
      macos-option-as-alt = lib.mkIf meta.isDarwin true;

      # Tabs/splits are zellij's (../../shell/zellij.nix): release the keys it binds.
      keybind = map (key: "${key}=unbind") (
        if meta.isDarwin then
          [
            "super+t"
            "super+w"
            "super+shift+["
            "super+shift+]"
            "super+9"
            "super+d"
            "super+shift+d"
            "super+["
            "super+]"
            "super+f"
            "super+g"
            "ctrl+tab"
            "ctrl+shift+tab"
          ]
          ++ lib.concatMap (n: [
            "super+${toString n}"
            "super+digit_${toString n}"
          ]) (lib.range 1 8)
          ++
            lib.concatMap
              (arrow: [
                "super+alt+arrow_${arrow}"
                "super+ctrl+arrow_${arrow}"
              ])
              [
                "up"
                "down"
                "left"
                "right"
              ]
        else
          map (n: "alt+${toString n}") (lib.range 1 9)
          ++ map (n: "alt+digit_${toString n}") (lib.range 1 8)
          ++ [ "ctrl+shift+t" ]
      );
    };
  };
}
