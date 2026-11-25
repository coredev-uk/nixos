# Machine-readable removal condition for every patch in ./default.nix `modifications`. The prose
# there says why; this says when, so CI can flag a patch that can go (.github/scripts/overlay-expiry.sh).
# A `modifications` entry without one here, or one here without a patch, fails `checks.<system>.overlay-expiry`.
#
# Conditions:
#   nixpkgsAbove "<package>" "<version>"  expired once every nixpkgs the overlay is applied to has
#                                         <package> newer than <version> (checked unpatched)
#   manual "<what to look for>"           can't be checked; never reported, just says what to watch
{ inputs }:
let
  nixpkgsAbove = package: version: {
    kind = "nixpkgs-above";
    inherit package version;
  };
  manual = text: {
    kind = "manual";
    inherit text;
  };

  conditions = {
    nh = nixpkgsAbove "nh" "4.5.0";

    plezy = manual "Plezy describes its fp16 video surface to Wayland (linux/runner/mpv/wayland_video_surface.cc)";

    beammp-launcher = manual "nixpkgs' beammp-launcher runs on NixOS without steam-run, or the launcher stops needing the CEF libs";

    gnome-network-displays = manual "gnome-network-displays' Zero Latency x264 preset has a short keyframe interval, or Chromecast lag is gone";

    qtmultimedia-vaapi-layers = manual "upstream qtmultimedia enables VAExportUseLayers and imports planes with the driver's RG88/RG1616 formats";

    nvidia-vaapi-driver-git = nixpkgsAbove "nvidia-vaapi-driver" "0.0.18";

    xdg-desktop-portal-hyprland = manual "xdg-desktop-portal-hyprland can change a running screen share's source (dynamic cast target)";
  };

  # Every nixpkgs the overlays are applied to (lib/helpers.nix): NixOS hosts use `nixpkgs`;
  # home-manager, nix-darwin and the `unstable` module argument use `unstable`. athena (WSL) is
  # x86_64-linux, poseidon aarch64-darwin.
  targets = [
    {
      name = "nixpkgs";
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    }
    {
      name = "unstable";
      pkgs = inputs.unstable.legacyPackages.x86_64-linux;
    }
    {
      name = "unstable";
      pkgs = inputs.unstable.legacyPackages.aarch64-darwin;
    }
  ];

  inherit (builtins)
    all
    any
    attrNames
    compareVersions
    ;
  unique = builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ];

  evaluate =
    name: cond:
    if cond.kind == "manual" then
      {
        expired = false;
        reason = cond.text;
      }
    else
      let
        # null when the package is gone from a nixpkgs: not provably newer, so never expired.
        versions = map (t: {
          inherit (t) name;
          version = t.pkgs.${cond.package}.version or null;
        }) targets;
        seen = unique (map (v: "${toString v.version} on ${v.name}") versions);
        expired = all (v: v.version != null && compareVersions v.version cond.version > 0) versions;
        # One version everywhere reads as "nixpkgs now has"; otherwise list per nixpkgs.
        shown =
          if builtins.length (unique (map (v: v.version) versions)) == 1 then
            "nixpkgs now has ${cond.package} ${toString (builtins.head versions).version}"
          else
            "${cond.package} ${builtins.concatStringsSep ", " seen}";
      in
      {
        inherit expired;
        reason = "${shown} (> ${cond.version})";
      };
in
{
  inherit conditions;

  # name -> { expired, reason }; manual conditions are always `expired = false`.
  status = builtins.mapAttrs evaluate conditions;

  # Coverage mismatch against the overlay (cheap: attribute names only, no package is evaluated).
  coverage =
    let
      patched = attrNames ((import ./default.nix { }).modifications { } { });
      declared = attrNames conditions;
    in
    {
      withoutCondition = builtins.filter (n: !(conditions ? ${n})) patched;
      withoutOverlay = builtins.filter (n: !(any (p: p == n) patched)) declared;
    };
}
