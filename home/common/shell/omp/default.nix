{
  pkgs,
  lib,
  inputs,
  meta,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs lib inputs; };

  # Read-only overlay via PI_CONFIG_FILES instead of programs.omp.settings, which overwrites
  # ~/.omp/agent/config.yml each switch and drops omp's own writes (setupVersion, UI settings).
  ompConfig = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    # Nerd Font glyphs (Symbols Nerd Font, installed with Ghostty).
    symbolPreset = "nerd";
    composer.shape = "box";
    theme = {
      dark = "titanium";
      light = "light";
    };
    retry = {
      waitForUsageReset = true;
    };
    modelRoles = {
      default = "anthropic/claude-opus-5-5";
      plan = "anthropic/claude-opus-5-5:high";
      slow = "anthropic/claude-opus-5-5:max";
      task = "anthropic/claude-sonnet-5-5";
      smol = "anthropic/claude-haiku-5-5";
      commit = "anthropic/claude-haiku-5-5";
    };
    task = {
      showResolvedModelBadge = true;
      agentModelOverrides = {
        task = "@task";
        sonic = "@smol";
        scout = "anthropic/claude-sonnet-5-5";
        reviewer = "@slow";
        security-reviewer = "anthropic/claude-opus-5-5:high";
      };
    };
    # Read from the store.
    skills.customDirectories = [ "${skills}" ];
  };

  # Prefix PI_CONFIG_FILES so the environment's still layers on top. LD_LIBRARY_PATH unset: a
  # devenv shell's newer-glibc libs break omp's WebKit host and Nix's Chromium (`GLIBC_2.43' not
  # found`); `devenv shell --` restores it for project commands.
  package = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  omp = pkgs.symlinkJoin {
    inherit (package) name;
    paths = [ package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/omp --prefix PI_CONFIG_FILES : ${ompConfig} --unset LD_LIBRARY_PATH
    '';
  };
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  # https://omp.sh
  programs.omp = {
    enable = true;
    package = omp;
  };

  # Runs taste-skill's scripts.
  home.packages = [ pkgs.nodejs ];

  # Taste-skill's inspector otherwise only looks in FHS paths.
  home.sessionVariables = lib.mkIf meta.isDesktop {
    CHROME_PATH = lib.getExe pkgs.chromium;
  };
}
