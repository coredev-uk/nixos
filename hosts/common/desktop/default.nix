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
  ++ lib.optional meta.isDesktop ./${meta.desktop}.nix;

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

  # Enable location services
  location.provider = "geoclue2";

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
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
