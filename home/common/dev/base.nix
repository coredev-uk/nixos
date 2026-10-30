{ self, pkgs, ... }:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;
in
{
  programs = {

    # Kubernetes CLI
    k9s = {
      enable = true;
      settings.k9s.ui.skin = "meridian";
      # k9s turns colour names into fixed RGB (olive is #808000, not the terminal's yellow), so
      # its skin can't follow the terminal and takes the palette itself. The terminal's own
      # background shows through; rows are enamel, gilt marks keys, focus and the sort column,
      # and only state (pending, errors) gets colour.
      skins.meridian.k9s = {
        body = {
          fgColor = m.text;
          bgColor = "default";
          logoColor = m.gilt;
        };
        prompt = {
          fgColor = m.text;
          bgColor = "default";
          suggestColor = m.muted;
        };
        help = {
          fgColor = m.text;
          bgColor = "default";
          sectionColor = m.text2;
          keyColor = m.gilt;
          numKeyColor = m.text2;
        };
        frame = {
          title = {
            fgColor = m.text;
            bgColor = "default";
            highlightColor = m.gilt;
            counterColor = m.text2;
            filterColor = m.gilt;
          };
          border = {
            fgColor = m.rule;
            focusColor = m.muted;
          };
          menu = {
            fgColor = m.text2;
            keyColor = m.gilt;
            numKeyColor = m.text2;
          };
          crumbs = {
            fgColor = m.ground;
            bgColor = m.text2;
            activeColor = m.gilt;
          };
          status = {
            newColor = m.text;
            modifyColor = m.text;
            addColor = m.ok;
            pendingColor = m.caution;
            errorColor = m.alert;
            highlightColor = m.gilt;
            killColor = m.muted;
            completedColor = m.muted;
          };
        };
        info = {
          fgColor = m.text;
          sectionColor = m.text2;
        };
        views = {
          table = {
            fgColor = m.text;
            bgColor = "default";
            cursorFgColor = m.ground;
            cursorBgColor = m.text;
            markColor = m.gilt;
            header = {
              fgColor = m.text2;
              bgColor = "default";
              sorterColor = m.gilt;
            };
          };
          xray = {
            fgColor = m.text;
            bgColor = "default";
            cursorColor = m.selection;
            cursorTextColor = m.text;
            graphicColor = m.text2;
          };
          charts = {
            bgColor = "default";
            chartBgColor = "default";
            dialBgColor = "default";
            defaultDialColors = [
              m.ok
              m.alert
            ];
            defaultChartColors = [
              m.ok
              m.alert
            ];
            resourceColors = {
              cpu = [
                m.ok
                m.caution
              ];
              mem = [
                m.ok
                m.caution
              ];
            };
          };
          yaml = {
            keyColor = m.text2;
            valueColor = m.text;
            colonColor = m.muted;
          };
          logs = {
            fgColor = m.text;
            bgColor = "default";
            indicator = {
              fgColor = m.text2;
              bgColor = "default";
              toggleOnColor = m.gilt;
              toggleOffColor = m.muted;
            };
          };
        };
        dialog = {
          fgColor = m.text;
          bgColor = m.plate;
          buttonFgColor = m.text;
          buttonBgColor = m.selection;
          buttonFocusFgColor = m.ground;
          buttonFocusBgColor = m.gilt;
          labelFgColor = m.text2;
          fieldFgColor = m.text;
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    devenv.enable = true;

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
