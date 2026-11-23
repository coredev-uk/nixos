# atlas's Zen (home/common/programs/zen.nix) for Windows, through the Zen flake's Home Manager
# module as on atlas, with the profile at /tmp/athena-zen/zen/default: apply.ps1 links that to
# the Windows profile before running the module's activation there. Nothing of it is installed in
# WSL, so this is its own Home Manager evaluation rather than part of paul@athena.
{
  self,
  inputs,
  lib,
  pkgs,
}:
let
  zen =
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      extraSpecialArgs = {
        inherit self inputs;
        meta = {
          inherit (pkgs.stdenv.hostPlatform) system;
          isDarwin = false;
        };
      };
      modules = [
        "${self}/home/common/programs/zen.nix"
        {
          home = {
            username = "paul";
            homeDirectory = "/home/paul";
            stateVersion = "26.05";
          };
          xdg.configHome = "/tmp/athena-zen";
          # Nix updates Zen on Linux; on Windows it updates itself.
          programs.zen-browser.policies.DisableAppUpdate = lib.mkForce false;
        }
      ];
    }).config;
  profile = "${zen.programs.zen-browser.profilesPath}/default";
in
{
  # For the install (distribution\policies.json).
  policies = (pkgs.formats.json { }).generate "policies.json" {
    inherit (zen.programs.zen-browser) policies;
  };
  # For the profile.
  userJs = zen.home.file."${profile}/user.js".source;
  containers = zen.home.file."${profile}/containers.json".source;

  # `activate <profile>`: links the Windows profile (its WSL path) where the module's scripts look
  # for it, then runs the module's activation for it (spaces, pins, extension buttons).
  activate = pkgs.writeShellScript "zen-activate" ''
    # The tools Home Manager's activation puts on PATH, which the module's scripts expect.
    export PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          coreutils
          findutils
          gnugrep
          gnused
          jq
        ]
        ++ zen.home.extraActivationPath
      )
    }:$PATH
    mkdir -p ${dirOf profile}
    ln -sfn "$1" ${profile}
    VERBOSE_ECHO=echo
    ${zen.home.activation.zen-browser-default.data}
  '';
}
