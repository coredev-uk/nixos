_: {
  atlas = [
    {
      output = "DP-1";
      mode = "2560x1440@180";
      position = "2560x0";
      scale = 1;
      bitdepth = 10;
      cm = "hdredid";
      sdr_max_luminance = 250;
    }
    {
      output = "DP-2";
      mode = "2560x1440@144";
      position = "0x0";
      scale = 1;
      bitdepth = 10;
      cm = "hdredid";
      sdr_max_luminance = 250;
    }
  ];

  default = [
    {
      output = "";
      mode = "preferred";
      position = "auto";
      scale = 1;
    }
  ];
}
