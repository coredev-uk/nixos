{
  desktop,
  pkgs,
  self,
  lib,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ../hardware/yubikey.nix
    ../services/pipewire.nix
    ./qt.nix
  ] ++ lib.optional (desktop != null) (./common/${desktop}.nix);

  # Enable Plymouth and suppress some logs by default.
  boot.plymouth.enable = true;
  boot.kernelParams = [
    # The 'splash' arg is included by the plymouth option
    "quiet"
    "loglevel=3"
    "rd.udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];

  hardware.graphics.enable = true;

  # Enable location services
  location.provider = "geoclue2";

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
  };

  fonts = {
    packages = with pkgs; [
      liberation_ttf
      ubuntu_font_family
      gyre-fonts

      # Compatibility Fonts
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans

      theme.fonts.default.package
      theme.fonts.emoji.package
      theme.fonts.iconFont.package
      theme.fonts.monospace.package
    ];

    # Use fonts specified by user rather than default ones
    enableDefaultPackages = false;

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
