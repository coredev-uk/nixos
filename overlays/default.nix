{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    fladder =
      (prev.fladder.override {
        targetFlutterPlatform = "linux";
      }).overrideAttrs
        (oldAttrs: {
          buildInputs = (oldAttrs.buildInputs or [ ]) ++ final.mpv-unwrapped.buildInputs;

          desktopItems = (oldAttrs.desktopItems or [ ]) ++ [
            (final.makeDesktopItem {
              name = "fladder";
              desktopName = "Fladder";
              comment = oldAttrs.meta.description;
              exec = "Fladder";
              icon = "fladder";
              terminal = false;
              type = "Application";
              categories = [
                "AudioVideo"
                "Video"
                "Network"
              ];
              keywords = [
                "Jellyfin"
                "Media"
                "Streaming"
              ];
            })
          ];

          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
            final.copyDesktopItems
          ];

          postInstall = (oldAttrs.postInstall or "") + ''
            install -Dm644 $out/app/fladder/data/flutter_assets/icons/fladder_icon.svg \
              $out/share/icons/hicolor/scalable/apps/fladder.svg
          '';
        });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.unstable {
      inherit (final) system;
      config.allowUnfree = true;
      overlays = [
        (_final: _prev: {
          # example = prev.example.overrideAttrs (oldAttrs: rec {
          # ...
          # });

        })
      ];
    };
  };
}
