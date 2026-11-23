# Windows half of `nixos-rebuild switch`: copies the flake's rendered home files (./default.nix)
# and theme fonts into place, optionally debloats (-Debloat, once, fresh install), then runs
# gaming.winget and dev.winget (-GamingOnly skips dev). -Test only reports drift.
# Run from an elevated PowerShell, from the flake's checkout in NixOS-WSL (it builds there):
#   powershell -ExecutionPolicy Bypass -File \\wsl.localhost\NixOS\home\paul\.dotfiles\hosts\athena\windows\apply.ps1
param(
  [switch]$GamingOnly,
  [switch]$Debloat,
  [switch]$Test
)
$ErrorActionPreference = 'Stop'

# Checkout this script runs from: \\wsl.localhost\<distro>\<path>\hosts\athena\windows.
if ($PSScriptRoot -notmatch '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)\\hosts\\athena\\windows$') {
  throw "Run apply.ps1 from the flake's checkout in WSL (\\wsl.localhost\<distro>\...), not $PSScriptRoot"
}
$distro = $Matches[1]
$flake = $Matches[2] -replace '\\', '/'
$out = wsl.exe -d $distro --cd $flake -- nix build --no-link --print-out-paths '.#nixosConfigurations.athena.config.system.build.windows'
if ($LASTEXITCODE) { throw "nix build of the Windows files failed ($LASTEXITCODE)" }
$rendered = "\\wsl.localhost\$distro" + ($out.Trim() -replace '/', '\')

# Rendered <folder>\<path> goes to <path> under that known folder (./default.nix).
$folders = [ordered]@{
  USERPROFILE  = $env:USERPROFILE
  APPDATA      = $env:APPDATA
  LOCALAPPDATA = $env:LOCALAPPDATA
  Documents    = [Environment]::GetFolderPath('MyDocuments')
}
$files = [ordered]@{}
foreach ($folder in $folders.Keys) {
  $root = Join-Path $rendered $folder
  if (-not (Test-Path -LiteralPath $root)) { continue }
  # -Force: dotfiles can carry the hidden attribute.
  foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
    $files[$file.FullName] = Join-Path $folders[$folder] $file.FullName.Substring($root.Length + 1)
  }
}
# Vicinae layers home-manager.json over settings.json. It splits VICINAE_OVERRIDES on ':' and
# reads "C:\…" as two paths, so drop the drive: "\Users\…" resolves on the current drive.
$vicinaeOverrides = ($env:LOCALAPPDATA -replace '^[A-Za-z]:', '') + '\vicinae\config\home-manager.json'
if ([Environment]::GetEnvironmentVariable('VICINAE_OVERRIDES', 'User') -ne $vicinaeOverrides) {
  if ($Test) { Write-Host 'differs: VICINAE_OVERRIDES' }
  else { [Environment]::SetEnvironmentVariable('VICINAE_OVERRIDES', $vicinaeOverrides, 'User') }
}
# Fonts: file in the user's font folder, name in the registry.
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$fontKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
foreach ($font in Get-ChildItem "$rendered\fonts") {
  $files[$font.FullName] = Join-Path $fontDir $font.Name
}

# Zen (home/common/programs/zen.nix): policies go in the install; user.js and containers.json in
# the profile (installs.ini's Default=), which needs a prior first run. Only while Zen is closed:
# it rewrites containers.json and the activation (below) edits its session file.
$zenInstall = "$env:ProgramFiles\Zen Browser"
$zenInstalls = "$env:APPDATA\zen\installs.ini"
$zenProfile = $null
if (Test-Path "$zenInstall\zen.exe") {
  $files["$rendered\zen\policies.json"] = "$zenInstall\distribution\policies.json"
  $default = if (Test-Path $zenInstalls) { Select-String -Path $zenInstalls -Pattern '^Default=(.+)$' | Select-Object -First 1 }
  if (-not $default) {
    Write-Warning 'Zen has no profile yet: start it once, close it, and apply again'
  } elseif (Get-Process zen -ErrorAction SilentlyContinue) {
    Write-Warning 'Zen is running: close it and apply again for its profile (prefs, containers, spaces and pins)'
  } else {
    $zenProfile = Join-Path "$env:APPDATA\zen" ($default.Matches[0].Groups[1].Value -replace '/', '\')
    $files["$rendered\zen\user.js"] = "$zenProfile\user.js"
    $files["$rendered\zen\containers.json"] = "$zenProfile\containers.json"
  }
}

foreach ($src in $files.Keys) {
  $dest = $files[$src]
  # Literal paths: "…[wght].ttf" is a wildcard to -Path.
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

# Zen module's activation (spaces, pins, extension buttons) on the Windows profile via the link
# from ./zen.nix. -e skips the shell so the profile path (spaces) stays one argument.
if ($zenProfile -and -not $Test) {
  $linuxProfile = (wsl.exe -d $distro -e wslpath -u $zenProfile).Trim()
  wsl.exe -d $distro -e "$($out.Trim())/zen/activate" $linuxProfile
  if ($LASTEXITCODE) { throw "Zen's activation failed ($LASTEXITCODE)" }
}

# WinUtil headless (-Config) from the pinned, hash-checked release. To bump: change both and check
# winutil.json's names still exist in its config/tweaks.json and config/appx.json.
if ($Debloat -and -not $Test) {
  $winutilVersion = '26.11.13'
  $winutilSha256 = 'e9d05a59d564b4fbb61fcfa1a594504a0f81e8d27c787119e72a99b57ddbe66d'
  # Its "Delete temp files" tweak empties %TEMP% mid-run, so use its own folder.
  $dir = "$env:LOCALAPPDATA\winutil"
  New-Item -ItemType Directory -Force $dir | Out-Null
  $script = "$dir\winutil-$winutilVersion.ps1"
  $config = "$dir\athena.json"
  Invoke-WebRequest "https://github.com/ChrisTitusTech/winutil/releases/download/$winutilVersion/winutil.ps1" -OutFile $script -UseBasicParsing
  if ((Get-FileHash $script -Algorithm SHA256).Hash -ne $winutilSha256) { throw "winutil.ps1 $winutilVersion does not match its pinned SHA-256" }
  Copy-Item "$PSScriptRoot\winutil.json" $config -Force
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Config $config
  # Tweaks aren't idempotent (second Explorer folder discovery counts an error): warn, carry on.
  if ($LASTEXITCODE) { Write-Warning "WinUtil reported errors ($LASTEXITCODE): see $dir\logs" }
  Remove-Item $script, $config
}

# winget configure files need the extended features (DSC), off by default.
winget configure --enable | Out-Null

$configs = @('gaming.winget') + $(if ($GamingOnly) { @() } else { @('dev.winget') })
foreach ($c in $configs) {
  $path = Join-Path $PSScriptRoot $c
  if ($Test) {
    # Non-zero on drift: reported, not an error.
    winget configure test -f $path --accept-configuration-agreements --disable-interactivity
    continue
  }
  winget configure -f $path --accept-configuration-agreements --disable-interactivity
  if ($LASTEXITCODE) { throw "winget configure $c failed ($LASTEXITCODE)" }
}
