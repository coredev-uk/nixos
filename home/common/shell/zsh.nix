{ flakePath, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh-syntax-highlighting
  ];

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

        eval "$(nh completions --shell zsh)"  # nix-home completions
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "zoxide"
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

      plugins = [ ];

      shellAliases = {
        la = "ls -la";
        ".." = "cd ..";
        ls = "eza -gl --git --group-directories-first --color=automatic";
        tree = "eza --tree";
        cat = "bat";

        ip = "ip --color";
        ipb = "ip --color --brief";

        gac = "git add -A  && git commit -a";
        gp = "git push";
        gst = "git status -sb";

        open = "xdg-open";

        opget = "op item get \"$(op item list --format=json | jq -r '.[].title' | fzf)\"";

        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";

        cleanup = "nh clean all --keep 4";
        nix-update = "nix flake update --flake ${flakePath}; nh os switch ${flakePath}; nh home switch ${flakePath}";

        grep = "grep --color=auto";
        vim = "nvim";
        nvm = "fnm";
      };
    };
  };
}
