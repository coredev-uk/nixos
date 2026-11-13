{
  pkgs,
  lib,
  inputs,
  meta,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs lib inputs; };

  # Settings as a read-only overlay layered over ~/.omp/agent/config.yml (PI_CONFIG_FILES; it
  # beats the global and project layers), rather than programs.omp.settings: that copies
  # config.yml over on every switch, dropping what omp writes there itself (setupVersion, so
  # its setup flow would rerun, and settings changed in the UI). The keys set here win over it.
  ompConfig = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    # Nerd Font glyphs (Symbols Nerd Font, installed with Ghostty). Also shows the
    # subscription icon on spend rather than the `unicode` preset's literal "S".
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
    # Read in place from the store, beside omp's own ~/.omp/agent/skills.
    skills.customDirectories = [ "${skills}" ];
  };

  # omp from its flake, prefixed so a PI_CONFIG_FILES from the environment still layers on top.
  package = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  omp = pkgs.symlinkJoin {
    inherit (package) name;
    paths = [ package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/omp --prefix PI_CONFIG_FILES : ${ompConfig}
    '';
  };
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  # oh-my-pi coding agent (https://omp.sh)
  programs.omp = {
    enable = true;
    package = omp;
  };

  # Node runs taste-skill's scripts (direction draw, lint, browser inspector).
  home.packages = [ pkgs.nodejs ];

  # taste-skill's inspector drives Chrome over CDP and only looks in FHS paths otherwise.
  home.sessionVariables = lib.mkIf meta.isDesktop {
    CHROME_PATH = lib.getExe pkgs.chromium;
  };
}
