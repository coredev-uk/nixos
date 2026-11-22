# Applies athena's Windows configuration, the Windows half of `nixos-rebuild switch`:
#   1. the home files: files/ beside this script, and those the flake renders (./default.nix:
#      Wintty's and Vicinae's config, VS Code's settings), each overwritten with the
#      repository's (Home Manager's role); the theme's fonts, installed for the user;
#   2. with -Debloat (once, on a fresh install): Chris Titus Tech's WinUtil, pinned, applying
#      winutil.json's tweaks and removing its Store apps;
#   3. gaming.winget, then dev.winget unless -GamingOnly (winget configure: installs what's missing).
#
# From an elevated PowerShell, run from the flake's checkout in NixOS-WSL (it builds the rendered
# files there):
#   powershell -ExecutionPolicy Bypass -File \\wsl.localhost\NixOS\home\paul\.dotfiles\hosts\athena\windows\apply.ps1
# `-Test` only reports drift (winget configure test) and changes nothing.
param(
  [switch]$GamingOnly,
  [switch]$Debloat,
  [switch]$Test
)
$ErrorActionPreference = 'Stop'

# The checkout this script runs from: \\wsl.localhost\<distro>\<path>\hosts\athena\windows.
if ($PSScriptRoot -notmatch '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)\\hosts\\athena\\windows$') {
  throw "Run apply.ps1 from the flake's checkout in WSL (\\wsl.localhost\<distro>\...), not $PSScriptRoot"
}
$distro = $Matches[1]
$flake = $Matches[2] -replace '\\', '/'
$out = wsl.exe -d $distro --cd $flake -- nix build --no-link --print-out-paths '.#nixosConfigurations.athena.config.system.build.windows'
if ($LASTEXITCODE) { throw "nix build of the Windows files failed ($LASTEXITCODE)" }
$rendered = "\\wsl.localhost\$distro" + ($out.Trim() -replace '/', '\')

$home_ = $env:USERPROFILE
$files = [ordered]@{
  "$PSScriptRoot\files\gitconfig"       = "$home_\.config\git\config"
  "$PSScriptRoot\files\allowed_signers" = "$home_\.config\git\allowed_signers"
  "$PSScriptRoot\files\ssh_config"      = "$home_\.ssh\config"
  "$PSScriptRoot\files\common_hosts"    = "$home_\.ssh\common_hosts"
  "$PSScriptRoot\files\bashrc"          = "$home_\.bashrc"
  "$PSScriptRoot\files\bash_profile"    = "$home_\.bash_profile"
  "$PSScriptRoot\files\wslconfig"       = "$home_\.wslconfig"
  "$rendered\wintty\config.wintty"      = "$home_\.config\wintty\config.wintty"
  "$rendered\vicinae\meridian.toml"     = "$env:LOCALAPPDATA\vicinae\data\themes\meridian.toml"
  "$rendered\vicinae\home-manager.json" = "$env:LOCALAPPDATA\vicinae\config\home-manager.json"
  "$rendered\vscode\settings.json"      = "$env:APPDATA\Code\User\settings.json"
}
# Vicinae layers home-manager.json over its own settings.json (as on Linux). It splits
# VICINAE_OVERRIDES on ':' (a Unix path list) and reads "C:\…" as two paths, so the path goes
# without its drive: Vicinae resolves "\Users\…" on the current drive.
$vicinaeOverrides = ($env:LOCALAPPDATA -replace '^[A-Za-z]:', '') + '\vicinae\config\home-manager.json'
if ([Environment]::GetEnvironmentVariable('VICINAE_OVERRIDES', 'User') -ne $vicinaeOverrides) {
  if ($Test) { Write-Host 'differs: VICINAE_OVERRIDES' }
  else { [Environment]::SetEnvironmentVariable('VICINAE_OVERRIDES', $vicinaeOverrides, 'User') }
}
# Fonts for this user: the file in the user's font folder, and its name in the registry.
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$fontKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
foreach ($font in Get-ChildItem "$rendered\fonts") {
  $files[$font.FullName] = Join-Path $fontDir $font.Name
}

foreach ($src in $files.Keys) {
  $dest = $files[$src]
  # Literal paths: a variable font's name ("…[wght].ttf") is a wildcard to -Path.
  $same = (Test-Path -LiteralPath $dest) -and
    ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dest).Hash)
  if (-not $same) {
    if ($Test) { Write-Host "differs: $dest"; continue }
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dest -Force
    Write-Host "wrote $dest"
  }
  if (-not $Test -and (Split-Path $dest) -eq $fontDir) {
    $name = "$([IO.Path]::GetFileNameWithoutExtension($dest)) (TrueType)"
    if ((Get-ItemProperty $fontKey -Name $name -ErrorAction SilentlyContinue).$name -ne $dest) {
      New-ItemProperty $fontKey -Name $name -Value $dest -PropertyType String -Force | Out-Null
    }
  }
}

# WinUtil's own headless mode (-Config: the list its Export writes), from the release pinned here
# and checked against its hash. To move to a newer release, change both and check winutil.json's
# names still exist in its config/tweaks.json and config/appx.json.
if ($Debloat -and -not $Test) {
  $winutilVersion = '26.11.13'
  $winutilSha256 = 'e9d05a59d564b4fbb61fcfa1a594504a0f81e8d27c787119e72a99b57ddbe66d'
  # In WinUtil's own folder: its "Delete temp files" tweak empties %TEMP% while it runs.
  $dir = "$env:LOCALAPPDATA\winutil"
  New-Item -ItemType Directory -Force $dir | Out-Null
  $script = "$dir\winutil-$winutilVersion.ps1"
  $config = "$dir\athena.json"
  Invoke-WebRequest "https://github.com/ChrisTitusTech/winutil/releases/download/$winutilVersion/winutil.ps1" -OutFile $script -UseBasicParsing
  if ((Get-FileHash $script -Algorithm SHA256).Hash -ne $winutilSha256) { throw "winutil.ps1 $winutilVersion does not match its pinned SHA-256" }
  Copy-Item "$PSScriptRoot\winutil.json" $config -Force
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Config $config
  # Its tweaks aren't idempotent (a second run of Explorer's folder discovery finds the keys the
  # first deleted and counts an error), so an error is reported and the apply carries on.
  if ($LASTEXITCODE) { Write-Warning "WinUtil reported errors ($LASTEXITCODE): see $dir\logs" }
  Remove-Item $script, $config
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
