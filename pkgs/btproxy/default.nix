# ESPHome-compatible Bluetooth proxy for a Linux host's own adapter (hermes, for Home Assistant).
# Built like upstream's release binaries; the nobluez tag leaves out BlueZ and D-Bus, which the
# kernel backend hermes runs doesn't use.
{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
# go.mod requires Go 1.27.3; nixpkgs' default `go` is older.
buildGo127Module (finalAttrs: {
  pname = "btproxy";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "yuzi-co";
    repo = "btproxy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-daZ5krjZ2hk/nu6c/v+9AMAin4MG9Twhu/xIOwfkEVE=";
  };

  vendorHash = "sha256-hJqVZx6VC378cTgsF6tWbWKsv5Cnp8x0uILzF8ho8jU=";

  subPackages = [ "cmd/btproxy" ];
  tags = [ "nobluez" ];
  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  meta = {
    description = "ESPHome-compatible Bluetooth proxy for Home Assistant, without an ESP32";
    homepage = "https://github.com/yuzi-co/btproxy";
    license = lib.licenses.mit;
    mainProgram = "btproxy";
    platforms = lib.platforms.linux;
  };
})
