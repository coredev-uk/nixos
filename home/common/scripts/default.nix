{ pkgs, ... }:

let
  killwine = pkgs.writeScriptBin "killwine" (builtins.readFile ./killwine.sh);
  set-brightness-all = pkgs.writeScriptBin "set-brightness-all" (builtins.readFile ./brightness.sh);
in
{
  home.packages = [
    # script deps
    pkgs.brightnessctl

    # scripts
    killwine
    set-brightness-all
  ];
}
