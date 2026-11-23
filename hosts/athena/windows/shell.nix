# Linux's shell on Windows: PowerShell 7 (Wintty's shell, and VS Code's terminal) with the same
# prompt, aliases, eza flags, fzf colours, bat theme and atuin settings as zsh, all read from
# paul@athena's home configuration (`home`, home/common/shell).
{
  lib,
  pkgs,
  home,
}:
let
  inherit (home) programs;
  # zsh's aliases that mean the same on Windows (including Home Manager's eza ones, ll and lt).
  # The rest are Linux's own.
  aliases = lib.getAttrs [
    "ls"
    "la"
    "tree"
    "cat"
    "gac"
    "gst"
    "ll"
    "lt"
  ] programs.zsh.shellAliases;
in
{
  # PowerShell's aliases take no arguments, so each is a function; its own aliases of the same
  # names (ls, cat) would win over a function, so they go first. `&&` needs PowerShell 7.
  profile = pkgs.writeText "profile.ps1" ''
    # Managed by apply.ps1 (hosts/athena/windows/default.nix), from home/common/shell.
    $env:BAT_THEME = '${programs.bat.config.theme}'
    $env:FZF_DEFAULT_OPTS = '${lib.concatStringsSep " " programs.fzf.defaultOptions}'

    oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\theme.omp.json" | Invoke-Expression
    Invoke-Expression (& { (zoxide init ${lib.concatStringsSep " " programs.zoxide.options} powershell | Out-String) })
    atuin init powershell | Out-String | Invoke-Expression

    function eza { eza.exe ${lib.concatStringsSep " " programs.eza.extraOptions} @args }
    ${lib.concatStrings (
      lib.mapAttrsToList (name: command: ''
        Remove-Alias -Name ${name} -Force -ErrorAction SilentlyContinue
        function ${name} { ${command} @args }
      '') aliases
    )}
  '';

  promptTheme = "${programs.oh-my-posh.package}/share/oh-my-posh/themes/${programs.oh-my-posh.useTheme}.omp.json";

  # atuin's settings without the daemon, which is a systemd socket on Linux.
  atuinConfig = (pkgs.formats.toml { }).generate "config.toml" (
    removeAttrs programs.atuin.settings [ "daemon" ]
  );
}
