{ unstable, ... }:
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

  # Lock screen auth; password only, no U2F.
  security.pam.services.quickshell-lock = { };

  # KMS capture needs gsr-kms-server's cap_sys_admin wrapper; without it every recording asks
  # for root via polkit.
  programs.gpu-screen-recorder.enable = true;
}
