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
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        # fzf-tab: colours from FZF_DEFAULT_OPTS
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      ''
      # webkit2gtk (Tauri apps) needs glib-networking for TLS (tauri-apps/wry#605). Appended, not replaced.
      + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
      '';

      oh-my-zsh = {
        enable = true;
        # Nix store is read-only: skip compaudit scan (~20ms/shell) and self-update.
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

      # Must load after oh-my-zsh's compinit, before zsh-syntax-highlighting.
      plugins = [
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        }
      ];

      # oh-my-zsh, nixvim and programs.eza already provide `..`, `gp`, grep, `vim`, ll/lla/lt.
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
        # Time sync is systemd-timesyncd, not chrony.
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
