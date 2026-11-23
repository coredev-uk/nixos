_: {
  # TODO: switch to hyprsunset when https://github.com/hyprwm/hyprsunset/pull/72 is merged
  services.wlsunset = {
    enable = true;

    inherit (import ../../../../lib/location.nix) latitude longitude;

    temperature = {
      day = 6500;
      night = 4000;
    };
  };
}
