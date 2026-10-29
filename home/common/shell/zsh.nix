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
      # Styles in ANSI names, so they follow the terminal's Meridian palette (and stay
      # legible over ssh in any terminal). Commands green, builtins blue, strings yellow,
      # comments bright black (fg=8), errors red.
      syntaxHighlighting = {
        enable = true;
        styles = {
          default = "none";
          unknown-token = "fg=red";
          reserved-word = "fg=magenta";
          alias = "fg=green";
          suffix-alias = "fg=green,underline";
          global-alias = "fg=cyan";
          builtin = "fg=blue";
          function = "fg=green";
          command = "fg=green";
          precommand = "fg=green,underline";
          hashed-command = "fg=green";
          arg0 = "fg=green";
          commandseparator = "fg=magenta";
          autodirectory = "fg=blue,underline";
          path = "underline";
          path_prefix = "underline";
          globbing = "fg=cyan";
          history-expansion = "fg=magenta";
          single-hyphen-option = "fg=cyan";
          double-hyphen-option = "fg=cyan";
          command-substitution-delimiter = "fg=magenta";
          process-substitution-delimiter = "fg=magenta";
          back-quoted-argument-delimiter = "fg=magenta";
          single-quoted-argument = "fg=yellow";
          double-quoted-argument = "fg=yellow";
          dollar-quoted-argument = "fg=yellow";
          single-quoted-argument-unclosed = "fg=red";
          double-quoted-argument-unclosed = "fg=red";
          dollar-quoted-argument-unclosed = "fg=red";
          back-quoted-argument-unclosed = "fg=red";
          dollar-double-quoted-argument = "fg=cyan";
          back-double-quoted-argument = "fg=cyan";
          back-dollar-quoted-argument = "fg=cyan";
          rc-quote = "fg=cyan";
          redirection = "fg=magenta";
          comment = "fg=8";
        };
      };

      initContent = ''
        # Completion styling
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        # fzf-tab: take fzf's (Meridian) colours from FZF_DEFAULT_OPTS, preview directories
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'

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
