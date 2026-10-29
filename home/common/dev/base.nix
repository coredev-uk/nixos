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
      # Tables on the ground with a hover-blue cursor row; gilt marks the focused frame,
      # the crumb you're on and key hints. Red is left to errors and kills.
      skins.meridian.k9s = {
        body = {
          fgColor = m.text;
          bgColor = m.ground;
          logoColor = m.gilt;
        };
        prompt = {
          fgColor = m.text;
          bgColor = m.inset;
          suggestColor = m.muted;
        };
        help = {
          fgColor = m.text;
          bgColor = m.ground;
          sectionColor = m.text2;
          keyColor = m.gilt;
          numKeyColor = m.link;
        };
        frame = {
          title = {
            fgColor = m.text;
            bgColor = m.ground;
            highlightColor = m.gilt;
            counterColor = m.text2;
            filterColor = m.link;
          };
          border = {
            fgColor = m.rule;
            focusColor = m.gilt;
          };
          menu = {
            fgColor = m.text2;
            keyColor = m.gilt;
            numKeyColor = m.link;
          };
          crumbs = {
            fgColor = m.text;
            bgColor = m.plate;
            activeColor = m.gilt;
          };
          status = {
            newColor = m.link;
            modifyColor = m.text;
            addColor = m.ok;
            pendingColor = m.caution;
            errorColor = m.alert;
            highlightColor = m.gilt;
            killColor = m.alert;
            completedColor = m.muted;
          };
        };
        info = {
          fgColor = m.text2;
          sectionColor = m.text;
        };
        views = {
          table = {
            fgColor = m.text;
            bgColor = m.ground;
            cursorFgColor = m.text;
            cursorBgColor = m.hover;
            markColor = m.gilt;
            header = {
              fgColor = m.text2;
              bgColor = m.ground;
              sorterColor = m.gilt;
            };
          };
          xray = {
            fgColor = m.text;
            bgColor = m.ground;
            cursorColor = m.hover;
            cursorTextColor = m.text;
            graphicColor = m.link;
          };
          charts = {
            bgColor = m.ground;
            chartBgColor = m.ground;
            dialBgColor = m.ground;
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
                m.series1
                m.series4
              ];
              mem = [
                m.series2
                m.series3
              ];
            };
          };
          yaml = {
            keyColor = m.link;
            valueColor = m.text;
            colonColor = m.muted;
          };
          logs = {
            fgColor = m.text;
            bgColor = m.ground;
            indicator = {
              fgColor = m.text2;
              bgColor = m.ground;
              toggleOnColor = m.gilt;
              toggleOffColor = m.muted;
            };
          };
        };
        dialog = {
          fgColor = m.text;
          bgColor = m.plate;
          buttonFgColor = m.text;
          buttonBgColor = m.hover;
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

    # Git
    git.enable = true;
    lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
        # Gilt for the focused panel and search; the cursor row on hover, as in fzf and k9s.
        gui.theme = {
          activeBorderColor = [
            m.gilt
            "bold"
          ];
          inactiveBorderColor = [ m.rule ];
          searchingActiveBorderColor = [ m.giltHover ];
          optionsTextColor = [ m.text2 ];
          selectedLineBgColor = [ m.hover ];
          inactiveViewSelectedLineBgColor = [ m.plate ];
          cherryPickedCommitFgColor = [ m.ground ];
          cherryPickedCommitBgColor = [ m.link ];
          markedBaseCommitFgColor = [ m.ground ];
          markedBaseCommitBgColor = [ m.gilt ];
          # Unstaged work isn't an error; red stays for errors and destructive actions.
          unstagedChangesColor = [ m.caution ];
          defaultFgColor = [ m.text ];
          authorColors."*" = m.text2;
        };
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
