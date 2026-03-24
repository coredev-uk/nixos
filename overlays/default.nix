{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    cider-2 = prev.cider-2.overrideAttrs (_old: {
      version = "2.0.3";
      src = builtins.fetchurl {
        url = "file:///home/paul/apps/cider-v2.0.3-linux-x64.deb";
        sha256 = "0xj3a6vzw9lv9w78yf2vkdgh2wwg6azbpjfd8cvb038cknm5gd6f";
      };

      postInstall = ''
        if [ -f "$out/lib/cider/resources/app.asar" ]; then
          ${final.lib.getExe final.asar} extract $out/lib/cider/resources/app.asar ./cider-build

          if ls ./cider-build/.vite/build/events-*.js >/dev/null 2>&1; then
            for eventsFile in ./cider-build/.vite/build/events-*.js; do
              substituteInPlace "$eventsFile" \
                --replace-warn 'else if(c.includes(r))return{action:"allow"}' 'else if(c.includes(r))return{action:"allow",overrideBrowserWindowOptions:{webPreferences:{devTools:!0,nodeIntegration:!1,contextIsolation:!0,webSecurity:!1,sandbox:!1,experimentalFeatures:!0}}}'
            done
          fi

          ${final.lib.getExe final.asar} pack ./cider-build $out/lib/cider/resources/app.asar
          rm -rf ./cider-build
        fi

        ln -sf ${final.widevine-cdm}/share/google/chrome/WidevineCdm $out/lib/cider/
      '';
    });

    discord-krisp-patcher =
      assert !(prev ? krisp-patcher);
      prev.writers.writePython3Bin "krisp-patcher"
        {
          libraries = with prev.python3Packages; [
            capstone
            pyelftools
          ];
          flakeIgnore = [
            "E501"
            "F403"
            "F405"
          ];
        }
        (
          builtins.readFile (
            builtins.fetchurl {
              url = "https://codeberg.org/keysmashes/sys/raw/branch/main/common/nixpkgs/programs/krisp-patcher.py";
              sha256 = "sha256-h8Jjd9ZQBjtO3xbnYuxUsDctGEMFUB5hzR/QOQ71j/E=";
            }
          )
        );
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
