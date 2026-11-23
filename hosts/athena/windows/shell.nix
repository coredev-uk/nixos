# PowerShell 7 profile mirroring the zsh setup (prompt, aliases, eza, fzf, bat, atuin), read from
# paul@athena's home config.
{
  lib,
  pkgs,
  home,
}:
let
  inherit (home) programs;
  # zsh aliases that make sense on Windows; the rest are Linux-only.
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
  # Aliases take no args, so each is a function; the built-in aliases (ls, cat) shadow functions,
  # so remove them first.
  profile = pkgs.writeText "profile.ps1" ''
    # Managed by apply.ps1 (hosts/athena/windows/default.nix).
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

  # No daemon: it's a systemd socket on Linux.
  atuinConfig = (pkgs.formats.toml { }).generate "config.toml" (
    removeAttrs programs.atuin.settings [ "daemon" ]
  );
}
