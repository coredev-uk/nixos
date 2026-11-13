# omp's skills as one store directory, read through `skills.customDirectories` (default.nix).
# Each entry is a directory holding a SKILL.md, named after its frontmatter `name`. Adding one
# is an input (`flake = false`) in flake.nix and a line below; `nix flake update <input>`
# moves it.
{
  pkgs,
  lib,
  inputs,
}:
let
  # Impeccable (https://impeccable.style), the build upstream generates for omp. Its launcher
  # (scripts/impeccable) runs the engine at scripts/bin/<os>-<arch>/impeccable before trying
  # to download one, so the engine release scripts/VERSION pins goes there, checked against
  # upstream's engine-checksums.txt. The wrapper keeps telemetry off whatever the environment
  # or ~/.impeccable/config.json say.
  impeccable =
    let
      src = "${inputs.impeccable}/.omp/skills/impeccable";
      version = lib.trim (builtins.readFile "${src}/scripts/VERSION");
      platform =
        {
          x86_64-linux = "linux-x64";
          aarch64-linux = "linux-arm64";
          x86_64-darwin = "darwin-x64";
          aarch64-darwin = "darwin-arm64";
        }
        .${pkgs.stdenv.hostPlatform.system};
      asset = "impeccable-${platform}";
      # engine-checksums.txt lines are "<version> <asset> <sha256>".
      checksums = builtins.readFile "${src}/scripts/engine-checksums.txt";
      prefix = lib.escapeRegex "${version} ${asset}";
      engine = pkgs.fetchurl {
        url = "https://github.com/pbakaus/impeccable/releases/download/engine-v${version}/${asset}";
        sha256 = builtins.elemAt (builtins.match "(.*\n)?${prefix} ([0-9a-f]{64})(\n.*)?" checksums) 1;
      };
    in
    pkgs.runCommand "impeccable-skill-${version}" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      cp -r ${src} $out
      chmod -R u+w $out
      install -Dm755 ${engine} $out/libexec/impeccable
      makeWrapper $out/libexec/impeccable $out/scripts/bin/${platform}/impeccable \
        --set IMPECCABLE_NO_TELEMETRY 1
    '';
in
pkgs.linkFarm "omp-skills" {
  inherit impeccable;
  # Taste Skill (https://tasteskill.dev). Its scripts need node and, for the browser
  # inspector, CHROME_PATH (default.nix).
  design-taste-frontend = "${inputs.taste-skill}/skills/taste-skill";
}
