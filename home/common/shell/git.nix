{
  meta,
  ...
}:
{
  home.file.".config/git/allowed_signers".text = ''
    core@coredev.uk ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7
    paul@coredev.uk ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7
  '';

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases.co = "pr checkout";
    };
  };

  programs.git =
    let
      opSignProgram =
        if meta.isDarwin then
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
          # From the system programs._1password-gui (hosts/common/desktop/1password.nix)
          "/run/current-system/sw/bin/op-ssh-sign";
    in
    {
      enable = true;

      # hasconfig matches remote.*.url as written in .git/config (before
      # url.*.insteadOf rewriting), so cover every GitHub URL form.
      includes =
        map
          (url: {
            condition = "hasconfig:remote.*.url:${url}";
            contents.user.email = "core@coredev.uk";
            contents.user.name = "Core";
          })
          [
            "git@github.com:*/**"
            "ssh://git@github.com/**"
            "https://github.com/**"
          ];

      settings = {
        user = {
          name = "Paul Thompson";
          email = "paul@coredev.uk";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7";
        };

        alias = {
          lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };

        core = {
          editor = "nvim";
          whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        };

        url."ssh://git@github.com/".insteadOf = "https://github.com/";

        url."ssh://git@gitlab.com/".insteadOf = "https://gitlab.com/";

        rerere = {
          enabled = 1;
          autoupdate = 1;
        };

        push = {
          default = "simple";
        };

        branch.sort = "-committerdate";

        pull.rebase = false;

        init.defaultBranch = "main";

        commit.gpgSign = true;

        tag.gpgSign = true;

        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = "~/.config/git/allowed_signers";
          ssh.program = opSignProgram;
        };

      };

      ignores = [
        ".vscode"
        ".npm"
        ".cache"
        ".icons"
        ".mozilla"
        ".local"
        ".electron-gyp"
        ".idea"
        ".lock"
        ".DS_Store"

        # Application Development
        "node_modules"
        "dist"
        "yarn-error.log"
        ".yarnclean"

        # Stuff
        "doc/tags"
        "*.vim-flavor"
        "*.swp"
        "*.bundle"
        "vendor"
      ];
    };
}
