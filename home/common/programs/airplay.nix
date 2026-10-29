{
  config,
  lib,
  pkgs,
  ...
}:

# AirPlay 2 audio out (the outputs under the panel's volume row, quickshell/config/services/AirPlay.qml).
# PipeWire's own AirPlay sender only speaks AirPlay 1, which the HomePod and the TV refuse
# (403 Forbidden), so OwnTone does the AirPlay 2 side: a PipeWire sink writes into a named pipe
# in OwnTone's library, OwnTone starts playing as soon as data arrives and streams it to the
# speakers selected through its JSON API (localhost:3689). Speakers play about a second behind
# the computer, so this is for music rather than for watching video. The firewall side (UDP
# 6001-6002 for the speakers' timing and control packets) is in hosts/common/desktop/casting.nix.
let
  stateDir = "${config.xdg.stateHome}/owntone";
  fifo = "${stateDir}/music/system.fifo";

  # Feeds the playing track's MPRIS metadata to OwnTone (called by the bar's AirPlay service).
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
      # Only the bar talks to it; the ports aren't open in the firewall either.
      trusted_networks = { "localhost" }
      # How far ahead of the speakers OwnTone streams, which is how late play, pause and the
      # sound itself reach them. The 2250 ms default is for first-generation AirPlay devices;
      # OwnTone's own docs suggest current ones cope with 500. Raise it if speakers drop out.
      start_buffer_ms = 750
    }
    library {
      name = "${config.home.username}"
      directories = { "${stateDir}/music" }
      pipe_autostart = true
    }
    # Nothing plays locally: the pipe's audio already came from this computer.
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

  # The sink the shell switches to for AirPlay. PipeWire reads this at startup: after changing it,
  # `systemctl --user restart pipewire` (or log in again).
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
