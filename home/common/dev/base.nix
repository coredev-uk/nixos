{ pkgs, ... }:
{
  programs = {

    # Kubernetes CLI
    k9s = {
      enable = true;
      settings.k9s.ui.skin = "terminal";
      # k9s's own skin is fixed RGB colours; this one names the terminal's ANSI colours
      # (tcell: olive = yellow, teal = cyan, silver = white, gray = bright black) and leaves
      # the background to the terminal, so k9s follows Ghostty's palette.
      skins.terminal.k9s = {
        body = {
          fgColor = "silver";
          bgColor = "default";
          logoColor = "olive";
        };
        prompt = {
          fgColor = "silver";
          bgColor = "default";
          suggestColor = "gray";
        };
        help = {
          fgColor = "silver";
          bgColor = "default";
          sectionColor = "teal";
          keyColor = "olive";
          numKeyColor = "teal";
        };
        frame = {
          title = {
            fgColor = "silver";
            bgColor = "default";
            highlightColor = "olive";
            counterColor = "gray";
            filterColor = "teal";
          };
          border = {
            fgColor = "gray";
            focusColor = "olive";
          };
          menu = {
            fgColor = "silver";
            keyColor = "olive";
            numKeyColor = "teal";
          };
          crumbs = {
            fgColor = "black";
            bgColor = "teal";
            activeColor = "olive";
          };
          status = {
            newColor = "teal";
            modifyColor = "silver";
            addColor = "green";
            pendingColor = "olive";
            errorColor = "maroon";
            highlightColor = "olive";
            killColor = "maroon";
            completedColor = "gray";
          };
        };
        info = {
          fgColor = "silver";
          sectionColor = "teal";
        };
        views = {
          table = {
            fgColor = "silver";
            bgColor = "default";
            cursorFgColor = "white";
            cursorBgColor = "black";
            markColor = "olive";
            header = {
              fgColor = "gray";
              bgColor = "default";
              sorterColor = "olive";
            };
          };
          yaml = {
            keyColor = "teal";
            valueColor = "silver";
            colonColor = "gray";
          };
          logs = {
            fgColor = "silver";
            bgColor = "default";
          };
        };
        dialog = {
          fgColor = "silver";
          bgColor = "default";
          buttonFgColor = "silver";
          buttonBgColor = "black";
          buttonFocusFgColor = "black";
          buttonFocusBgColor = "olive";
          labelFgColor = "teal";
          fieldFgColor = "silver";
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Git
    git.enable = true;
    lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
        # lazygit draws with the terminal's ANSI colours already; only its selected line is
        # blue by default, which the palette's light blue makes hard to read text on.
        gui.theme.selectedLineBgColor = [ "black" ];
      };
    };

    jq.enable = true;
  };

  home.packages = with pkgs; [
    # C++ tooling
    clang
    gnumake

    # Nix tooling
    deadnix
    nil
    nix-init
    nixfmt
    nurl
    statix
    treefmt

    # Python tooling
    (pkgs.python3.withPackages (
      p: with p; [
        virtualenv
        pyserial
      ]
    ))

    # Shell tooling
    shellcheck
    shfmt

    # Kubernetes
    kubectl
    kubernetes-helm
    fluxcd
    talosctl
  ];
}
