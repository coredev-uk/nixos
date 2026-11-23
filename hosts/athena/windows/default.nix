# athena's Windows home: every file apply.ps1 (beside this file) puts in place, rendered from the
# same modules as the Linux side so the two can't drift.
#
#   nix build .#nixosConfigurations.athena.config.system.build.windows
#
# The output is laid out by destination: <folder>/<path> goes to <path> under that Windows known
# folder (USERPROFILE, APPDATA, LOCALAPPDATA, Documents), overwritten on every apply (Home
# Manager's role). Two directories need apply.ps1's own handling:
#   fonts/  the theme's monospace, icon and shell fonts, installed for the user
#   zen/    atlas's Zen (./zen.nix), for the install and the profile Zen made on its first run
# Every file is a copy, not a link: Windows can't follow a symlink into /nix/store over
# \\wsl.localhost.
{
  self,
  inputs,
  outputs,
  lib,
  pkgs,
  meta,
  ...
}:
let
  # paul@athena, the home configuration in NixOS-WSL: git, ssh and the shell come from it.
  home = outputs.homeConfigurations."${meta.username}@${meta.hostname}".config;

  theme = import "${self}/lib/theme" { inherit pkgs; };
  ghostty = import "${self}/home/common/programs/ghostty/shared.nix" { inherit lib theme; };
  vicinae = import "${self}/home/common/programs/vicinae/shared.nix" { inherit theme; };
  shell = import ./shell.nix { inherit lib pkgs home; };
  zen = import ./zen.nix {
    inherit
      self
      inputs
      lib
      pkgs
      ;
  };

  json = (pkgs.formats.json { }).generate;
  toml = (pkgs.formats.toml { }).generate;
  # The first line of each file written here as text, for whoever finds it on Windows.
  managed = "# Managed by apply.ps1 (hosts/athena/windows in coredev-uk/nixos).";

  # Git for Windows' user config: home/common/shell/git.nix's settings, with Windows' OpenSSH
  # (which reaches Proton Pass's agent, \\.\pipe\openssh-ssh-agent; Git's bundled one doesn't)
  # for transport and signing, and LF kept (Sona's scripts run in Git Bash and it has no
  # .gitattributes). No editor: nvim is Linux's. ~/.gitconfig is left to tools (gh).
  git = home.programs.git.settings;
  gitConfig = pkgs.writeText "gitconfig" (
    managed
    + "\n"
    + lib.generators.toGitINI (
      git
      // {
        core = removeAttrs git.core [ "editor" ] // {
          sshCommand = "C:/Windows/System32/OpenSSH/ssh.exe";
          autocrlf = false;
        };
        gpg = lib.recursiveUpdate git.gpg {
          ssh.program = "C:/Windows/System32/OpenSSH/ssh-keygen.exe";
        };
      }
    )
  );

  # Wintty (Ghostty's core on Windows): Ghostty's theme and shared settings, in the format Home
  # Manager writes Ghostty's config in (`key = value`, a list as repeated keys), starting
  # PowerShell 7.
  winttyConfig = pkgs.writeText "config.wintty" (
    lib.generators.toKeyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    } (ghostty.meridian // ghostty.settings // { command = "pwsh.exe -NoLogo"; })
  );

  fontFamily = lib.concatMapStringsSep ", " (f: "'${f.name}'") [
    theme.fonts.monospace
    theme.fonts.iconFont
  ];

  files = {
    "USERPROFILE/.config/git/config" = gitConfig;
    "USERPROFILE/.config/git/allowed_signers" = home.home.file.".config/git/allowed_signers".source;
    # Windows' OpenSSH; keys come from Proton Pass's agent.
    "USERPROFILE/.ssh/config" = pkgs.writeText "ssh_config" ''
      ${managed}
      Host *
        UserKnownHostsFile ~/.ssh/common_hosts ~/.ssh/known_hosts

      Host github.com
        User git
    '';
    "USERPROFILE/.ssh/common_hosts" = home.home.file.".ssh/common_hosts".source;

    # Git Bash. Its /etc/profile replaces PKG_CONFIG_PATH with MSYS2's own: take back the user
    # variable (Sona's GStreamer .pc files, dev.winget's sona-env) so cgo finds them.
    "USERPROFILE/.bashrc" = pkgs.writeText "bashrc" ''
      ${managed}
      export PKG_CONFIG_PATH="$(cygpath -m "$LOCALAPPDATA")/sona-dev/gstreamer/sona-pkgconfig"
    '';
    "USERPROFILE/.bash_profile" = pkgs.writeText "bash_profile" ''
      ${managed}
      [ -f ~/.bashrc ] && . ~/.bashrc
    '';

    # WSL's VM. Nothing runs VMs inside NixOS-WSL. With nested virtualisation on, every VM start
    # probed for it and logged (and notified) "Failed to detect nested virtualization support,
    # error: ERROR_INVALID_DATA".
    "USERPROFILE/.wslconfig" = pkgs.writeText "wslconfig" ''
      ${managed}
      [wsl2]
      nestedVirtualization=false
    '';

    # PowerShell 7's profile for every host (Wintty, VS Code's terminal), and what it reads.
    "Documents/PowerShell/profile.ps1" = shell.profile;
    "USERPROFILE/.config/oh-my-posh/theme.omp.json" = shell.promptTheme;
    "USERPROFILE/.atuin/config.toml" = shell.atuinConfig;

    # The one file Wintty reads (its docs' ~/.config/wintty isn't).
    "APPDATA/wintty/config.wintty" = winttyConfig;

    # Vicinae: the theme, and the declarative settings layered over the app's own (writable)
    # settings.json through VICINAE_OVERRIDES (apply.ps1 sets it), as Home Manager does on Linux.
    # Win+Space is Windows' input switcher, so the launcher takes Alt+Space, PowerToys Run's key.
    "LOCALAPPDATA/vicinae/data/themes/meridian.toml" = toml "meridian.toml" vicinae.meridian;
    "LOCALAPPDATA/vicinae/config/home-manager.json" = json "home-manager.json" (
      lib.recursiveUpdate vicinae.settings { global_shortcuts.toggle = "alt+space"; }
    );

    "APPDATA/Code/User/settings.json" = json "settings.json" {
      # Sona's style: gofumpt (`check` fails otherwise) and golangci-lint.
      gopls."formatting.gofumpt" = true;
      "go.lintTool" = "golangci-lint";
      "go.toolsManagement.autoUpdate" = false;
      "files.eol" = "\n";
      "editor.fontFamily" = fontFamily;
      "terminal.integrated.fontFamily" = fontFamily;
    };

    "zen/policies.json" = zen.policies;
    "zen/user.js" = zen.userJs;
    "zen/containers.json" = zen.containers;
  };

  fonts = [
    theme.fonts.monospace
    theme.fonts.iconFont
    theme.fonts.shell
  ];
in
{
  system.build.windows = pkgs.runCommand "athena-windows" { } ''
    ${lib.concatStrings (
      lib.mapAttrsToList (dest: src: ''
        install -Dm644 ${src} ${lib.escapeShellArg "${placeholder "out"}/${dest}"}
      '') files
    )}
    install -Dm755 ${zen.activate} $out/zen/activate

    # One build of each face: Windows lists a family twice when it has both the .ttf and the
    # .otf, or a variable font beside its static cuts. Variable fonts first, then TrueType.
    mkdir -p $out/fonts
    for dir in ${lib.concatMapStringsSep " " (f: "${f.package}/share/fonts") fonts}; do
      # An array: a variable font's name ("…[wght].ttf") is a glob, which stdenv's nullglob drops.
      mapfile -t files < <(find "$dir" -type f \( -name '*\[*\].ttf' -o -name '*-VF.ttf' \))
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.ttf')
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.otf')
      install -m644 -t $out/fonts "''${files[@]}"
    done
  '';
}
