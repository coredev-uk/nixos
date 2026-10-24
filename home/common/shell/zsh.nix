{
  lib,
  pkgs,
  meta,
  ...
}:
{
  catppuccin.zsh-syntax-highlighting.enable = true;

  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "the-unnamed";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
      };

      initContent = ''
        # Completion styling
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

        export GIO_MODULE_DIR=${pkgs.glib-networking}/lib/gio/modules/ # Patch for webkit2gtk ssl error (https://github.com/tauri-apps/wry/issues/605#issuecomment-1215756032)
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "sudo"
          "ssh"
          "npm"
          "git"
          "aliases"
          "colored-man-pages"
          "docker"
        ];
      };

      plugins = [ ];

      # oh-my-zsh already provides: `..` (auto_cd), `gp` (git plugin) and a `grep` alias with
      # --color=auto plus VCS dir excludes. nixvim provides `vim`; programs.eza provides
      # ll/lla/lt and the shared eza flags.
      shellAliases = {
        ls = "eza -l";
        la = "ls -a";
        tree = "eza --tree";
        cat = "bat";

        gac = "git add -A && git commit";
        gst = "git status -sb";

        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";

        k = "kubectl";
      }
      // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        ip = "ip --color";
        ipb = "ip --color --brief";
        # chrony is disabled; time sync is systemd-timesyncd, which resyncs on restart.
        fix-time = "sudo systemctl restart systemd-timesyncd";
      }
      // (
        if meta.isDesktop then
          {
            open = "xdg-open";
          }
        else
          { }
      );
    };
  };
}
