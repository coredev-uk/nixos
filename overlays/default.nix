{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # fix for jellyfin/jellyfin-desktop#1112
    jellyfin-desktop = prev.jellyfin-desktop.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/jellyfin-desktop \
          --set QTWEBENGINE_CHROMIUM_FLAGS "--disable-gpu --disable-software-rasterizer --num-raster-threads=4" \
          --set QT_QUICK_BACKEND "software" \
          --set QT_XCB_GL_INTEGRATION "none"
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
