{
  config,
  lib,
  pkgs,
  inputs,
  unstable,
  ...
}:
let
  nix-citizen = inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system};

  # Every stream gets its own headless output, STREAM, at the client's resolution (the Xbox gets
  # real 4K) while the desk monitors stay as they are. It sits apart from them so the cursor can't
  # wander onto it, and runs at twice the client's frame rate so wlr capture takes each new frame
  # instead of ticking on Sunshine's clock. Removing it moves its windows to a desk monitor.
  streamDisplay = pkgs.writeShellApplication {
    name = "sunshine-stream-display";
    runtimeInputs = [
      config.programs.hyprland.package
      pkgs.jq
    ];
    text = ''
      case "$1" in
        start)
          hyprctl -j monitors | jq -e 'any(.[]; .name == "STREAM")' >/dev/null ||
            hyprctl output create headless STREAM
          mode="''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@$((SUNSHINE_CLIENT_FPS * 2))"
          hyprctl eval "hl.monitor({ output = \"STREAM\", mode = \"$mode\", position = \"10240x0\", scale = 1 })"
          hyprctl eval 'hl.dispatch(hl.dsp.focus({ monitor = "STREAM" }))'
          ;;
        stop)
          hyprctl output remove STREAM || true
          ;;
      esac
    '';
  };
in
{
  imports = [
    inputs.nix-citizen.nixosModules.default
  ];

  programs = {
    # Star Citizen (https://github.com/LovingMelody/nix-citizen)
    rsi-launcher = {
      enable = true;
      location = "$HOME/games/star-citizen";
      # Default overlay rebuilds wine-astral, dxvk and mingw GCC against our nixpkgs (hours,
      # uncached); nix-citizen's own packages are in its cachix. Explicit because the module's
      # no-overlay fallback indexes `self.packages` wrongly and fails to evaluate.
      includeOverlay = false;
      package = nix-citizen.rsi-launcher;
      wine = nix-citizen.wine-astral;
    };

    steam = {
      enable = true;

      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      protontricks = {
        enable = true;
      };

      # From unstable: GE-Proton releases faster than 26.05.
      extraCompatPackages = [
        unstable.proton-ge-bin
      ];

      package = pkgs.steam.override {
        extraPkgs = pkgs: [
          pkgs.corefonts
        ];
      };
    };

    # The user needs the gamemode group (users/paul): polkit only lets it change governor/GPU/procsys.
    gamemode = {
      enable = true;
      settings.general = {
        renice = 10;
        softrealtime = "auto";
      };
    };

    gamescope.enable = true;
  };

  # Game streaming to Moonlight (the Xbox, the Bravia's Google TV, the Mac). Settings live here, so
  # the web UI (https://localhost:47990) is for pairing and apps only; set its login on first visit,
  # since openFirewall exposes it to the LAN. The VFIO hook ends the user session, so Sunshine lets
  # go of the GPU before the VM takes it.
  services.sunshine = {
    enable = true;
    openFirewall = true;
    # Without CUDA the build can't load libcuda, so NVENC fails and it falls back to libx264.
    package = pkgs.sunshine.override { cudaSupport = true; };
    settings = {
      # wlr-screencopy can capture Hyprland's headless outputs; KMS (and CAP_SYS_ADMIN) can't.
      capture = "wlr";
      # Until a stream creates it, Sunshine falls back to DP-1 (its startup encoder probe).
      output_name = "STREAM";
      global_prep_cmd = builtins.toJSON [
        {
          do = "${lib.getExe streamDisplay} start";
          undo = "${lib.getExe streamDisplay} stop";
        }
      ];
    };
  };

  # Sunshine's ports (47984-48010) sit inside the ephemeral range, so an outgoing connection can hold
  # one and Sunshine fails to bind (RTSP on 48010). Keep them out of it.
  boot.kernel.sysctl."net.ipv4.ip_local_reserved_ports" = "47984-48010";

  # MOZA wheel settings (Pit House's role on Windows); input and force feedback need only the kernel's
  # hid-universal-pidff. Its udev rules open MOZA's ttyACM ports (0666) and give uinput the uaccess
  # tag Sunshine's rules already add.
  environment.systemPackages = [ pkgs.boxflat ];
  services.udev.packages = [ pkgs.boxflat ];

  # Open-file limit for every unit, so the uwsm session too (Esync); systemd's default soft is 1024.
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 524288;
  };
}
