# npiperelay.exe: stdin/stdout <-> Windows named pipe. Built for Windows, run from WSL via interop
# (home/common/wsl.nix: Proton Pass SSH agent).
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "npiperelay";
  version = "1.9.3";

  src = fetchFromGitHub {
    owner = "albertony";
    repo = "npiperelay";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ht4jKaXgo1HW3mp5T5A/q8kVxAJFc1h6HgeTVyZh4m8=";
  };

  # Vendored golang.org/x/sys.
  vendorHash = null;

  env.CGO_ENABLED = 0;
  # buildGoModule defaults GOOS/GOARCH to the build platform.
  preBuild = ''
    export GOOS=windows GOARCH=amd64
  '';
  ldflags = [ "-s" ];

  # Cross build installs under bin/windows_amd64.
  postInstall = ''
    mv $out/bin/windows_amd64/npiperelay.exe $out/bin/
    rmdir $out/bin/windows_amd64
  '';
  doCheck = false;

  meta = {
    description = "Access Windows named pipes from WSL";
    homepage = "https://github.com/albertony/npiperelay";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
})
