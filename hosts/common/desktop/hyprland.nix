{ lib, unstable, ... }:
{
  imports = [
    ./tiling-common.nix
    ./greeter.nix
    ./sudo-polkit.nix
  ];

  # Single Hyprland source (compositor, wrapper, session files, portal); Home Manager sets
  # `package = null`. Unstable to match the unstable Home Manager's Lua config.
  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
    portalPackage = unstable.xdg-desktop-portal-hyprland;
    withUWSM = true;
    xwayland.enable = true;
  };

  # A switch stops every changed user unit, and stopping any of uwsm's session services ends the
  # session (bindpid's OnSuccess= starts wayland-session-shutdown.target; wayland-wm@ is the
  # compositor). Their ExecStart embeds uwsm and util-linux store paths, so a nixpkgs bump logs the
  # user out. New units take over at the next login, as greetd's do (services.greetd.restart). Raw
  # drop-ins: systemd.user.services would also set PATH, which the compositor passes to apps.
  systemd.user.units =
    lib.genAttrs
      [
        "wayland-session-bindpid@.service"
        "wayland-wm@.service"
        "wayland-wm-env@.service"
      ]
      (_: {
        overrideStrategy = "asDropin";
        text = ''
          [Service]
          X-RestartIfChanged=false
        '';
      });

  # Lock screen auth; password only, no U2F.
  security.pam.services.quickshell-lock = { };

  # KMS capture needs gsr-kms-server's cap_sys_admin wrapper; without it every recording asks
  # for root via polkit.
  programs.gpu-screen-recorder.enable = true;
}
