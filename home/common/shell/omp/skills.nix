# omp skills as one store dir (skills.customDirectories in default.nix); each entry holds a SKILL.md
# named after its frontmatter `name`. Add one as a `flake = false` input plus a line below.
{
  pkgs,
  lib,
  inputs,
}:
let
  # Impeccable's launcher runs scripts/bin/<os>-<arch>/impeccable before trying to download, so
  # install the pinned engine (scripts/VERSION, checked against engine-checksums.txt) there.
  # Telemetry forced off.
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
  # Scripts need node and CHROME_PATH (default.nix).
  design-taste-frontend = "${inputs.taste-skill}/skills/taste-skill";
}
