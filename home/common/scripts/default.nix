{ pkgs, ... }:

let
  killwine = pkgs.writeShellApplication {
    name = "killwine";
    runtimeInputs = [ pkgs.procps ];
    text = builtins.readFile ./killwine.sh;
  };
  set-brightness-all = pkgs.writeShellApplication {
    name = "set-brightness-all";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
    ];
    text = builtins.readFile ./brightness.sh;
  };
in
{
  home.packages = [
    killwine
    set-brightness-all
  ];
}
