{
  pkgs,
  lib,
  inputs,
  meta,
  ...
}:
let
  # Impeccable (https://impeccable.style), the build upstream generates for omp. Its launcher
  # (scripts/impeccable) runs the engine at scripts/bin/<os>-<arch>/impeccable when there is
  # one and otherwise downloads it into ~/.impeccable, so the engine ships in the skill. The
  # engine is a static binary; its digest comes from upstream's engine-checksums.txt, so
  # `nix flake update impeccable` moves the skill and the engine together. The engine is
  # wrapped with IMPECCABLE_NO_TELEMETRY so its opt-out holds whatever the environment or
  # ~/.impeccable/config.json say.
  impeccableDir = "${inputs.impeccable}/.omp/skills/impeccable";
  impeccableVersion = lib.trim (builtins.readFile "${impeccableDir}/scripts/VERSION");
  impeccablePlatform =
    {
      x86_64-linux = "linux-x64";
      aarch64-linux = "linux-arm64";
      x86_64-darwin = "darwin-x64";
      aarch64-darwin = "darwin-arm64";
    }
    .${pkgs.stdenv.hostPlatform.system};
  impeccableAsset = "impeccable-${impeccablePlatform}";
  impeccableEngine = pkgs.fetchurl {
    url = "https://github.com/pbakaus/impeccable/releases/download/engine-v${impeccableVersion}/${impeccableAsset}";
    sha256 = lib.head (
      lib.concatMap (
        line:
        lib.defaultTo [ ] (
          builtins.match "${lib.escapeRegex impeccableVersion} ${impeccableAsset} ([0-9a-f]{64})" line
        )
      ) (lib.splitString "\n" (builtins.readFile "${impeccableDir}/scripts/engine-checksums.txt"))
    );
  };
  impeccableSkill =
    pkgs.runCommand "impeccable-skill" { nativeBuildInputs = [ pkgs.makeWrapper ]; }
      ''
        cp -r ${impeccableDir} $out
        chmod -R u+w $out
        install -Dm755 ${impeccableEngine} $out/libexec/impeccable
        makeWrapper $out/libexec/impeccable $out/scripts/bin/${impeccablePlatform}/impeccable \
          --set IMPECCABLE_NO_TELEMETRY 1
      '';
in
{
  imports = [ inputs.skills-nix.homeModules.default ];

  # Skills from the skills.sh registry, the same names as `npx skills add`: "owner/repo" for all
  # of a repo's skills, "owner/repo@skill" for one. skills-nix pins each repo from its weekly
  # copy of the registry, so `nix flake update skills-nix` moves them all. Installed straight
  # into omp's own skills directory, beside the two below that skills-nix can't provide. It
  # finds skills at `<dir>/SKILL.md`, under `skills/` or at a repo's root; a repo that keeps
  # them elsewhere (REA's `.agents/skills`, say) needs its own input instead.
  skills = {
    enable = true;
    dir = "~/.omp/agent/skills";
    install = [ ];
  };

  # oh-my-pi coding agent (https://omp.sh)
  # Node runs taste-skill's scripts (direction draw, lint, browser inspector).
  home.packages = [
    pkgs.omp
    pkgs.nodejs
  ];

  # taste-skill's inspector drives Chrome over CDP and only looks in FHS paths otherwise.
  home.sessionVariables = lib.mkIf meta.isDesktop {
    CHROME_PATH = lib.getExe pkgs.chromium;
  };

  home.file = {
    ".omp/agent/config.yml" = {
      force = true;
      source = (pkgs.formats.yaml { }).generate "omp-config.yml" {
        symbolPreset = "unicode";
        composer.shape = "box";
        theme = {
          dark = "titanium";
          light = "light";
        };
        setupVersion = 2;
      };
    };

    # Built here rather than taken from the registry: it needs its engine fetched and wrapped.
    ".omp/agent/skills/impeccable".source = impeccableSkill;
    # Taste Skill (https://tasteskill.dev), which isn't on skills.sh; installed under its
    # frontmatter name.
    ".omp/agent/skills/design-taste-frontend".source = "${inputs.taste-skill}/skills/taste-skill";
  };
}
