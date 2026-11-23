# athena's Windows home: files apply.ps1 puts in place, rendered from the same modules as Linux.
#
#   nix build .#nixosConfigurations.athena.config.system.build.windows
#
# Output is <folder>/<path> -> <path> under that Windows known folder (USERPROFILE, APPDATA,
# LOCALAPPDATA, Documents), overwritten every apply. Handled specially by apply.ps1:
#   fonts/  theme fonts, installed for the user
#   zen/    Zen (./zen.nix): install policies and the profile
# Files are copies: Windows can't follow /nix/store symlinks over \\wsl.localhost.
{
  inputs,
  outputs,
  lib,
  pkgs,
  meta,
  theme,
  ...
}:
let
  # paul@athena (NixOS-WSL home config): git, ssh, shell come from it.
  home = outputs.homeConfigurations."${meta.username}@${meta.hostname}".config;

  ghostty = import ../../../home/common/programs/ghostty/shared.nix { inherit lib theme; };
  vicinae = import ../../../home/common/programs/vicinae/shared.nix { inherit theme; };
  shell = import ./shell.nix { inherit lib pkgs home; };
  zen = import ./zen.nix {
    inherit
      inputs
      lib
      pkgs
      meta
      ;
  };

  json = (pkgs.formats.json { }).generate;
  toml = (pkgs.formats.toml { }).generate;
  # First line of text files written here, for whoever finds them on Windows.
  managed = "# Managed by apply.ps1 (hosts/athena/windows in coredev-uk/nixos).";

  # Git for Windows config: home/common/shell/git.nix settings, using Windows' OpenSSH (reaches
  # Proton Pass's \\.\pipe\openssh-ssh-agent; Git's bundled one doesn't) for transport and signing.
  # LF kept (Sona's scripts run in Git Bash; no .gitattributes). No editor (nvim is Linux's).
  # ~/.gitconfig is left to tools (gh).
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

  # Wintty (Ghostty core): Ghostty's theme and shared settings in HM's format (`key = value`, lists
  # as repeated keys), starting PowerShell 7.
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

    # Git Bash's /etc/profile replaces PKG_CONFIG_PATH: restore it (Sona's GStreamer .pc files,
    # dev.winget's sona-env) so cgo works.
    "USERPROFILE/.bashrc" = pkgs.writeText "bashrc" ''
      ${managed}
      export PKG_CONFIG_PATH="$(cygpath -m "$LOCALAPPDATA")/sona-dev/gstreamer/sona-pkgconfig"
    '';
    "USERPROFILE/.bash_profile" = pkgs.writeText "bash_profile" ''
      ${managed}
      [ -f ~/.bashrc ] && . ~/.bashrc
    '';

    # Nothing runs VMs in NixOS-WSL; nested virt made every VM start log
    # "Failed to detect nested virtualization support, error: ERROR_INVALID_DATA".
    "USERPROFILE/.wslconfig" = pkgs.writeText "wslconfig" ''
      ${managed}
      [wsl2]
      nestedVirtualization=false
    '';

    # PowerShell 7 profile for all hosts (Wintty, VS Code terminal), and its inputs.
    "Documents/PowerShell/profile.ps1" = shell.profile;
    "USERPROFILE/.config/oh-my-posh/theme.omp.json" = shell.promptTheme;
    "USERPROFILE/.atuin/config.toml" = shell.atuinConfig;

    # The only file Wintty reads (not ~/.config/wintty as its docs say).
    "APPDATA/wintty/config.wintty" = winttyConfig;

    # Vicinae: theme, plus declarative settings layered over its writable settings.json via
    # VICINAE_OVERRIDES (set by apply.ps1). Win+Space is Windows' input switcher: Alt+Space instead.
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

    # One build per face: Windows lists a family twice with both .ttf and .otf, or variable plus
    # static cuts. Variable first, then TrueType.
    mkdir -p $out/fonts
    for dir in ${lib.concatMapStringsSep " " (f: "${f.package}/share/fonts") fonts}; do
      # Array: "…[wght].ttf" is a glob that stdenv's nullglob drops.
      mapfile -t files < <(find "$dir" -type f \( -name '*\[*\].ttf' -o -name '*-VF.ttf' \))
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.ttf')
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.otf')
      install -m644 -t $out/fonts "''${files[@]}"
    done
  '';
}
