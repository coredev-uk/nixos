{
  lib,
  pkgs,
  meta,
  ...
}:
{
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
        # fzf-tab: take fzf's colours from FZF_DEFAULT_OPTS, preview directories
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      ''
      # webkit2gtk (Tauri apps) needs glib-networking for TLS
      # (https://github.com/tauri-apps/wry/issues/605#issuecomment-1215756032). Added to GIO's
      # search path rather than replacing it, so dconf and the other GIO modules still load.
      + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
      '';

      oh-my-zsh = {
        enable = true;
        # Skip compaudit's permission scan of every completion dir (~20ms per shell): they're
        # in the read-only nix store, which also has no git checkout to self-update.
        extraConfig = ''
          ZSH_DISABLE_COMPFIX=true
          zstyle ':omz:update' mode disabled
        '';
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

      # Sourced after oh-my-zsh's compinit and before zsh-syntax-highlighting.
      plugins = [
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        }
      ];

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

        speedtest = "speedtest-go";

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

  home.packages = [ pkgs.speedtest-go ];
}
