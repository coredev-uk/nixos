{
  pkgs,
  self,
  lib,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ../hardware/yubikey.nix
    ../services/pipewire.nix
  ]
  ++ lib.optionals meta.isDesktop [
    ./${meta.desktop}.nix
    ./casting.nix
  ];

  # Enable Plymouth and suppress some logs by default.
  boot.plymouth.enable = true;
  # Emitted as the `loglevel=` kernel param (and kernel.printk sysctl) by NixOS.
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    # The 'splash' arg is included by the plymouth option
    "quiet"
    "rd.udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];

  # VA-API on NVIDIA (nvidia-vaapi-driver) comes from hardware.nvidia.videoAcceleration.
  hardware.graphics.enable = true;

  # services.graphical-desktop turns on speech-dispatcher (and espeak) by default; nothing
  # here uses text-to-speech.
  services.speechd.enable = false;

  # A YubiKey touch instead of the password (pam_u2f), wherever it's enabled below; the password
  # still follows if the key isn't touched or plugged in. The keys are registered in
  # /etc/u2f_mappings, one line per user (`pamu2fcfg` for the first key, `pamu2fcfg -n` appended
  # for more): root-owned, so nothing running as the user can add a key of its own, and outside
  # /home, which the polkit helper can't see. Kept out of this (public) repo; without the file the
  # module just fails over to the password. Never `nouserok`: it would let a missing file pass.
  security.pam = {
    u2f.settings = {
      authfile = "/etc/u2f_mappings";
      # Says so, in the terminal and in the Quickshell polkit dialog (PolkitDialog.qml).
      cue = true;
      cue_prompt = "Touch your security key";
    };
    services = {
      login.u2f.enable = true;
      sudo.u2f.enable = true;
      # Every polkit prompt, and sudo through it (sudo-polkit.nix). Not the lock screen or the
      # greeter: a key left in the PC would open them to anyone at the desk, and the greeter's
      # password is what unlocks GNOME Keyring.
      polkit-1.u2f.enable = true;
    };
  };

  # polkit 127 runs its PAM helper as a sandboxed, socket-activated service with no devices
  # (PrivateDevices, DevicePolicy=strict), so pam_u2f found no key, or couldn't make its
  # challenge, and went straight to the password. The host's /dev, with only the hidraw nodes
  # (security keys) and /dev/urandom (the challenge) let through besides upstream's /dev/null;
  # Arch ships the same drop-in with pam_u2f (polkit-org/polkit#622).
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = [
      "/dev/urandom r"
      "char-hidraw rw"
    ];
  };

  fonts = {
    packages = with pkgs; [
      liberation_ttf
      ubuntu-classic
      gyre-fonts

      # Compatibility Fonts
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans

      theme.fonts.default.package
      theme.fonts.emoji.package
      theme.fonts.iconFont.package
      theme.fonts.monospace.package
    ];

    # Use fonts specified by user rather than default ones
    enableDefaultPackages = false;

    fontDir.enable = true;

    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        serif = [
          "${theme.fonts.default.name}"
          "${theme.fonts.emoji.name}"
        ];
        sansSerif = [
          "${theme.fonts.default.name}"
          "${theme.fonts.emoji.name}"
        ];
        monospace = [ "${theme.fonts.monospace.name}" ];
        emoji = [ "${theme.fonts.emoji.name}" ];
      };
    };
  };
}
