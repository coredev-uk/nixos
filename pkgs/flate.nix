{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.1.35";

  sources = {
    aarch64-darwin = {
      arch = "darwin_arm64";
      hash = "sha256-IIbGkO0KFgOimuysJ7fY5CJikBoqeY2Fgg1KZ6z72NQ=";
    };
    aarch64-linux = {
      arch = "linux_arm64";
      hash = "sha256-cSHPVVsbdfIpUsnh50MS/2o47DmUFOxHmmzXXmPmSxw=";
    };
    x86_64-darwin = {
      arch = "darwin_amd64";
      hash = "sha256-s+i2Zg6VabCeBf5xCGsbefZyQuzZVld3Hia00o65/r4=";
    };
    x86_64-linux = {
      arch = "linux_amd64";
      hash = "sha256-qIABs6is/gHq+Z5BH3OiFTyhOgBRrLHTrS4uaTQmVNg=";
    };
  };

  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "flate";
  inherit version;

  src = fetchurl {
    url = "https://github.com/home-operations/flate/releases/download/${version}/flate_${version}_${source.arch}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -D -m0755 flate $out/bin/flate

    runHook postInstall
  '';

  meta = {
    description = "Render and diff Flux GitOps repositories fully offline";
    homepage = "https://github.com/home-operations/flate";
    license = lib.licenses.agpl3Only;
    mainProgram = "flate";
    platforms = builtins.attrNames sources;
  };
}
