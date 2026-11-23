_: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # nh 4.5.0 (home-manager's, from unstable) passes `systemd-run --output=cat`,
    # which only systemd >= 261 accepts, so `nh os switch` fails activation on
    # NixOS 26.05. Backport the upstream fix (version check + `--pipe` fallback);
    # the version guard leaves 26.05's nh 4.4.2 and any later release untouched.
    nh = prev.nh.overrideAttrs (old: {
      patches =
        (old.patches or [ ])
        ++ final.lib.optional (old.version == "4.5.0") (
          final.fetchpatch {
            name = "nh-systemd-run-pipe-fallback.patch";
            url = "https://github.com/nix-community/nh/commit/a5adbe165150f7f26778616ec918d3a0f8437a0a.patch";
            excludes = [ "CHANGELOG.md" ];
            hash = "sha256-bGHkV+fS5U54tK6hkaflAnJKFcfZ3YHEWmO2h18Q37Y=";
          }
        );
    });
  };
}
