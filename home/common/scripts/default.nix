{ pkgs, ... }:

let

  clipboard-interop = pkgs.writeScriptBin "clipboard-interop" (
    builtins.readFile ./clipboard-interop.sh
  );
  killwine = pkgs.writeScriptBin "killwine" (builtins.readFile ./killwine.sh);
  set-brightness-all = pkgs.writeScriptBin "set-brightness-all" (builtins.readFile ./brightness.sh);
in
{
  home.packages = [
    # script deps
    pkgs.brightnessctl

    # scripts
    clipboard-interop
    killwine
    set-brightness-all
  ];
}
