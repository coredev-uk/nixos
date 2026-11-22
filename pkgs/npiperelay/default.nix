# npiperelay.exe: relays stdin/stdout to a Windows named pipe. Built for Windows (pure Go, no
# cgo) and run from WSL through interop: home/common/wsl.nix reaches Proton Pass's SSH agent with it.
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

  # The repository vendors golang.org/x/sys.
  vendorHash = null;

  env.CGO_ENABLED = 0;
  # buildGoModule sets GOOS and GOARCH from the build platform; this builds a Windows binary.
  preBuild = ''
    export GOOS=windows GOARCH=amd64
  '';
  ldflags = [ "-s" ];

  # A cross build puts the binary under bin/windows_amd64.
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
