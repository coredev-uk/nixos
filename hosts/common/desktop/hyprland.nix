{
  pkgs,
  lib,
  self,
  unstable,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [ ./tiling-common.nix ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.greetd.settings.default_session.command = ''
    ${lib.makeBinPath [ pkgs.tuigreet ]}/tuigreet -r --asterisks --time \
      --cmd 'env XDG_SESSION_DESKTOP=Hyprland XDG_CURRENT_DESKTOP=Hyprland GTK_THEME=${theme.gtkTheme.name} ${unstable.hyprland}/bin/start-hyprland'
  '';
}
