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

  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    # "splash" comes from the plymouth option
    "quiet"
    "rd.udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];

  # VA-API: hardware.nvidia.videoAcceleration.
  hardware.graphics.enable = true;

  # services.graphical-desktop enables speech-dispatcher; unused.
  services.speechd.enable = false;

  # YubiKey touch via pam_u2f where enabled below; the password still follows. Keys are in
  # /etc/u2f_mappings (`pamu2fcfg`, `pamu2fcfg -n` appended per extra key): root-owned so the user
  # can't add keys, outside /home (the polkit helper can't see it), and out of this public repo.
  # Never `nouserok`: a missing file would pass.
  security.pam = {
    u2f.settings = {
      authfile = "/etc/u2f_mappings";
      # Shown in the terminal and the Quickshell polkit dialog.
      cue = true;
      cue_prompt = "Touch your security key";
    };
    services = {
      login.u2f.enable = true;
      sudo.u2f.enable = true;
      # Every polkit prompt, and sudo via it (sudo-polkit.nix). Not lock screen/greeter: a key left
      # in the PC would open them, and the greeter's password unlocks GNOME Keyring.
      polkit-1.u2f.enable = true;
    };
  };

  # polkit 127 runs its PAM helper sandboxed with no devices, so pam_u2f can't reach the key and
  # falls through to the password. Allow hidraw (keys) and /dev/urandom (challenge).
  # Arch ships the same drop-in (polkit-org/polkit#622).
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

      # Fallbacks
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans

      theme.fonts.default.package
      theme.fonts.emoji.package
      theme.fonts.iconFont.package
      theme.fonts.monospace.package
    ];

    # Only the fonts listed here
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
