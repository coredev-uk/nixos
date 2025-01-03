{ flakePath, pkgs, ... }:

{

  home.packages = with pkgs; [
    zoxide
    starship
  ];

  catppuccin.zsh-syntax-highlighting.enable = true;

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
      };

      history = {
        save = 10000;
        size = 10000;
        path = "$HOME/.cache/zsh_history";
      };

      initExtra = ''
        # Completion styling
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

        export EDITOR=vim

        eval "$(nh completions --shell zsh)"  # nix-home completions
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "zoxide"
          "starship"
          "sudo"
          "ssh"
          "ssh-agent"
          "npm"
          "git"
          "aliases"
          "colored-man-pages"
          "docker"
        ];
      };

      # plugins = [
      #   {
      #     # will source zsh-autosuggestions.plugin.zsh
      #     name = "zsh-autosuggestions";
      #     src = pkgs.zsh-autosuggestions;
      #     file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      #   }
      #   {
      #     name = "zsh-completions";
      #     src = pkgs.zsh-completions;
      #     file = "share/zsh-completions/zsh-completions.zsh";
      #   }
      #   {
      #     name = "zsh-syntax-highlighting";
      #     src = pkgs.zsh-syntax-highlighting;
      #     file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      #   }
      #   {
      #     name = "fzf-tab";
      #     src = pkgs.zsh-fzf-tab;
      #     file = "share/fzf-tab/fzf-tab.plugin.zsh";
      #   }
      # ];

      shellAliases = {
        # ls = "eza -gl --git --color=automatic";
        # tree = "eza --tree";
        # cat = "bat";

        ip = "ip --color";
        ipb = "ip --color --brief";

        gac = "git add -A  && git commit -a";
        gp = "git push";
        gst = "git status -sb";

        open = "xdg-open";

        opget = "op item get \"$(op item list --format=json | jq -r '.[].title' | fzf)\"";

        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";

        cleanup = "nh clean all --keep 4";
        nix-update = "nix flake update --flake ${flakePath}; nh os switch ${flakePath}; nh home switch ${flakePath}; cleanup";
      };
    };
  };
}
