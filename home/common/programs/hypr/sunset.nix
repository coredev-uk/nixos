_: {

  # TODO: switch to hyprsunset when https://github.com/hyprwm/hyprsunset/pull/72 is merged

  services.wlsunset = {
    enable = true;

    latitude = "51.5074";
    longitude = "-0.1278";

    temperature = {
      day = 6500;
      night = 4000;
    };
  };
}
