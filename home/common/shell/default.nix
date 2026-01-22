{
  pkgs,
  self,
  lib,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ./bat.nix
    ./btop.nix
    ./fastfetch.nix
    ./nh.nix
    ./opencode.nix
    ./starship.nix
    ./ssh.nix
    ./zsh.nix
  ]
  ++ lib.optional (!meta.isHeadless) ./git.nix
  ++ lib.optionals meta.isDesktop [
    ./xdg.nix
  ];

  catppuccin = {
    inherit (theme.catppuccin) flavor;
    inherit (theme.catppuccin) accent;
  };

  programs = {
    direnv.enable = true;
    eza.enable = true;
    git.enable = true;
    home-manager.enable = true;
    jq.enable = true;
    lazygit = {
      enable = true;
      settings.promptToReturnFromSubprocess = false;
    };
  };

  home.packages = with pkgs; [
    age
    devenv
    self.packages.${meta.system}.nvim
    # termscp
    typst
  ];
}
