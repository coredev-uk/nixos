{
  config,
  lib,
  pkgs,
  ...
}:

# AirPlay 2 out via OwnTone (PipeWire's own sender is AirPlay 1 only; HomePod/TV refuse it with 403).
# A PipeWire sink writes into a pipe in OwnTone's library; speakers are picked via its JSON API
# (localhost:3689). ~1 s latency: music only. Firewall (UDP 6001-6002) is in hosts/common/desktop/casting.nix.
# UI: quickshell/config/services/AirPlay.qml.
let
  stateDir = "${config.xdg.stateHome}/owntone";
  fifo = "${stateDir}/music/system.fifo";

  # Called by the bar's AirPlay service.
  airplayMetadata = pkgs.writeShellApplication {
    name = "airplay-metadata";
    runtimeInputs = with pkgs; [
      coreutils
      curl
    ];
    text = ''
      fifo=${lib.escapeShellArg "${fifo}.metadata"}
    ''
    + builtins.readFile ./airplay-metadata.sh;
  };

  owntoneConf = pkgs.writeText "owntone.conf" ''
    general {
      uid = "${config.home.username}"
      db_path = "${stateDir}/songs3.db"
      cache_dir = "${stateDir}/cache"
      logfile = "${stateDir}/owntone.log"
      loglevel = log
      ipv6 = false
      # Bar only; ports aren't in the firewall either.
      trusted_networks = { "localhost" }
      # How far ahead of the speakers OwnTone streams (= play/pause/audio delay). Default 2250 is for
      # AirPlay 1 devices; 500+ suffices for current ones. Raise if speakers drop out.
      start_buffer_ms = 750
    }
    library {
      name = "${config.home.username}"
      directories = { "${stateDir}/music" }
      pipe_autostart = true
    }
    # Audio already came from this machine.
    audio {
      type = "disabled"
    }
    airplay_shared {
      control_port = 6001
      timing_port = 6002
    }
    mpd {
      port = 0
    }
  '';
in
{
  systemd.user.services.owntone = {
    Unit = {
      Description = "OwnTone, AirPlay 2 sender for the shell's sound outputs";
      After = [ "pipewire.service" ];
    };
    Service = {
      ExecStartPre = "${pkgs.writeShellScript "owntone-prepare" ''
        mkdir -p ${lib.escapeShellArg "${stateDir}/music"} ${lib.escapeShellArg "${stateDir}/cache"}
        for pipe in ${lib.escapeShellArg fifo} ${lib.escapeShellArg "${fifo}.metadata"}; do
          [ -p "$pipe" ] || ${pkgs.coreutils}/bin/mkfifo "$pipe"
        done
      ''}";
      # No mDNS announcements: it's a sender, not a library to browse.
      ExecStart = "${pkgs.owntone}/bin/owntone -f -c ${owntoneConf} --mdns-no-rsp --mdns-no-daap --mdns-no-web --mdns-no-cname";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = [ airplayMetadata ];

  # Sink the shell switches to for AirPlay. Read at PipeWire start: restart it after changes.
  xdg.configFile."pipewire/pipewire.conf.d/60-airplay-sink.conf".text = builtins.toJSON {
    "context.modules" = [
      {
        name = "libpipewire-module-pipe-tunnel";
        args = {
          "tunnel.mode" = "sink";
          "pipe.filename" = fifo;
          # OwnTone's pipe format.
          "audio.format" = "S16LE";
          "audio.rate" = 44100;
          "audio.channels" = 2;
          "audio.position" = [
            "FL"
            "FR"
          ];
          "stream.props" = {
            "node.name" = "airplay";
            "node.description" = "AirPlay";
          };
        };
      }
    ];
  };
}
