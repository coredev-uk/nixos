# Applies athena's Windows configuration, the Windows half of `nixos-rebuild switch`:
#   1. the home files in files/ (Home Manager's role: each is overwritten with the repository's);
#   2. gaming.winget, then dev.winget unless -GamingOnly (winget configure: installs what's missing).
#
# From an elevated PowerShell, with the flake checked out in NixOS-WSL:
#   powershell -ExecutionPolicy Bypass -File \\wsl.localhost\NixOS\home\paul\.dotfiles\hosts\athena\windows\apply.ps1
# `-Test` only reports drift (winget configure test) and copies nothing.
param(
  [switch]$GamingOnly,
  [switch]$Test
)
$ErrorActionPreference = 'Stop'

$home_ = $env:USERPROFILE
$files = [ordered]@{
  'gitconfig'            = "$home_\.config\git\config"
  'allowed_signers'      = "$home_\.config\git\allowed_signers"
  'ssh_config'           = "$home_\.ssh\config"
  'common_hosts'         = "$home_\.ssh\common_hosts"
  'bashrc'               = "$home_\.bashrc"
  'bash_profile'         = "$home_\.bash_profile"
  'vscode-settings.json' = "$env:APPDATA\Code\User\settings.json"
}
foreach ($name in $files.Keys) {
  $src = Join-Path $PSScriptRoot "files\$name"
  $dest = $files[$name]
  $same = (Test-Path $dest) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $dest).Hash)
  if ($same) { continue }
  if ($Test) { Write-Host "differs: $dest"; continue }
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $src $dest -Force
  Write-Host "wrote $dest"
}

# Configuration files need winget's extended features (the DSC processor), off by default.
winget configure --enable | Out-Null

$configs = @('gaming.winget') + $(if ($GamingOnly) { @() } else { @('dev.winget') })
foreach ($c in $configs) {
  $path = Join-Path $PSScriptRoot $c
  if ($Test) {
    # Non-zero when the system has drifted: reported, not an error.
    winget configure test -f $path --accept-configuration-agreements --disable-interactivity
    continue
  }
  winget configure -f $path --accept-configuration-agreements --disable-interactivity
  if ($LASTEXITCODE) { throw "winget configure $c failed ($LASTEXITCODE)" }
}
