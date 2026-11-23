# atlas's Zen (home/common/programs/zen.nix) for Windows via the Zen flake's HM module. Own HM
# evaluation (not paul@athena): profile at /tmp/athena-zen/zen/default, which apply.ps1 links to
# the Windows profile before running the activation.
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
          # Zen self-updates on Windows.
          programs.zen-browser.policies.DisableAppUpdate = lib.mkForce false;
        }
      ];
    }).config;
  profile = "${zen.programs.zen-browser.profilesPath}/default";
in
{
  # Install: distribution\policies.json.
  policies = (pkgs.formats.json { }).generate "policies.json" {
    inherit (zen.programs.zen-browser) policies;
  };
  # Profile.
  userJs = zen.home.file."${profile}/user.js".source;
  containers = zen.home.file."${profile}/containers.json".source;

  # `activate <profile>`: links the Windows profile (WSL path) where the module's scripts expect
  # it, then runs the activation (spaces, pins, extension buttons).
  activate = pkgs.writeShellScript "zen-activate" ''
    # PATH the module's scripts expect from HM activation.
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
