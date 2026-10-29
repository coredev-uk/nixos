{
  pkgs,
  ...
}:
let
  libx = import ./lib.nix { inherit (pkgs) lib; };
in
rec {
  inherit (libx) hexToRgb;

  # Meridian: the system palette (home/common/programs/quickshell/DESIGN.md). The Quickshell
  # shell's config/common/Theme.qml holds the same values; Hyprland, Vicinae, Ghostty, Neovim,
  # GTK, Qt and Discord read them from here. Programs running in the terminal use its 16
  # colours instead of their own copy.
  meridian = {
    # Grounds
    ground = "#151920";
    plate = "#222830";
    inset = "#191d24";
    hover = "#2d333e";
    rule = "#363d49";
    selection = "#47505e";
    # Legends
    text = "#ece5d3";
    text2 = "#a9a493";
    muted = "#6d717a";
    # Accent ("here" and "on") and slider fills
    gilt = "#c9a24f";
    giltHover = "#d8b468";
    fill = "#bdb9a9";
    # State
    alert = "#e06c5a";
    caution = "#e0954f";
    ok = "#6fb39a";
    link = "#8fb0d3";
    # Categorical, never state
    series1 = "#8fb0d3";
    series2 = "#6fb39a";
    series3 = "#d39a8f";
    series4 = "#a99ad6";

    # Code in the editor (Neovim): more chroma than the shell's state colours, which are read
    # at a glance, because syntax is read in colour line after line. All at least 7:1 on the
    # ground.
    syntax = {
      keyword = "#b69cf2";
      string = "#8ccf8a";
      function = "#79b3f0";
      type = "#56c7c2";
      constant = "#f0a060";
      special = "#e8917f";
    };

    # The 16 ANSI colours, for terminals and the CLI tools that draw with them. Normal on the
    # ground is at least 5:1, bright at least 6.9:1; bright black (comments, hints) 3.6:1.
    # Yellow is gilt, so a terminal's emphasis reads like the shell's.
    terminal = {
      background = "#151920";
      foreground = "#ece5d3";
      cursor = "#c9a24f";
      selectionBackground = "#47505e";
      selectionForeground = "#ece5d3";
      normal = {
        black = "#222830";
        red = "#e06c5a";
        green = "#6fb39a";
        yellow = "#c9a24f";
        blue = "#8fb0d3";
        magenta = "#a99ad6";
        cyan = "#79b4b6";
        white = "#bdb9a9";
      };
      bright = {
        black = "#6b727e";
        red = "#ea8676";
        green = "#8cc7b0";
        yellow = "#d8b468";
        blue = "#a9c4e0";
        magenta = "#bdb1e3";
        cyan = "#98c9ca";
        white = "#ece5d3";
      };
    };
  };

  gtkTheme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };

  cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  fonts = {
    default = {
      name = "Inter";
      package = pkgs.inter;
      size = 11;
    };
    # The Quickshell shell's face (Meridian, home/common/programs/quickshell/DESIGN.md), also
    # Hyprland's group tabs and Vicinae, so everything around the windows reads as one.
    shell = {
      name = "Atkinson Hyperlegible Next";
      package = pkgs.atkinson-hyperlegible-next;
    };
    iconFont = {
      name = "Symbols Nerd Font";
      package = pkgs.nerd-fonts.symbols-only;
    };
    monospace = {
      name = "Fira Code";
      package = pkgs.fira-code;
    };
    emoji = {
      name = "Joypixels";
      package = pkgs.joypixels;
    };
  };
}
