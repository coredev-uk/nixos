<img src="assets/logo.svg" alt="" width="100" align="left">

### NixOS Configuration

[![Flake Checks](https://img.shields.io/github/actions/workflow/status/coredev-uk/nixos/nix-check.yml?branch=main&label=flake%20checks)](https://github.com/coredev-uk/nixos/actions/workflows/nix-check.yml)
[![Hosts](https://img.shields.io/github/actions/workflow/status/coredev-uk/nixos/hosts.yml?branch=main&label=hosts)](https://github.com/coredev-uk/nixos/actions/workflows/hosts.yml)
[![Last commit](https://img.shields.io/github/last-commit/coredev-uk/nixos.svg)](https://github.com/coredev-uk/nixos/commits)

Core's Nix flake for NixOS and macOS: one configuration per machine, from disk layout to desktop.

[Hosts](#hosts) •
[Bootstrap](#bootstrap) •
[Write-up](https://coredev.uk/projects/nixos-configuration/) •
[Binary cache](https://github.com/coredev-uk/home-ops/blob/main/docs/nix-cache.md)

<br clear="left">

<img src="assets/atlas.webp" alt="The atlas desktop on Hyprland: flake.nix open in Neovim on the left; on the right, fastfetch showing NixOS 26.05 with an AMD Ryzen 7 3700X and an RTX 3080, above the repository's git log.">

## Hosts

<details>
<summary>Machines this flake configures</summary>

|  Hostname  |         OS         | Device  |    WM    | Status  |
| :--------: | :----------------: | :-----: | :------: | :-----: |
|  `atlas`   |       NixOS        | Desktop | Hyprland | Working |
| `poseidon` | macOS (nix-darwin) | Laptop  |   N/A    | Working |
|  `athena`  | Windows + NixOS-WSL | Desktop |   N/A    | Working |
|  `hermes`  |       NixOS        | Raspberry Pi 4 |   N/A    |   New   |

</details>

<details>
<summary>Where things live</summary>

| Path | Holds |
| :--- | :--- |
| `flake.nix`, `lib/helpers.nix` | Inputs, and the `mkHost`/`mkHome`/`mkDarwin` helpers every machine is built with |
| `lib/` | Data both sides read: `theme` (the `theme` module argument), `monitors.nix` (`meta.monitors`), `location.nix` |
| `hosts/<host>/` | One machine's system: `boot.nix`, `hardware.nix`, `extra.nix` |
| `hosts/common/` | System modules the hosts share (base, desktop, hardware, services, users) |
| `home/common/` | Home Manager: `shell` and `dev` everywhere, `desktop` on NixOS desktops, `programs/apps.nix` on every graphical host |
| `home/hosts/<host>.nix` | One machine's home extras (atlas: Kraken screen, workspace layout, DP-1 handoff to the laptop) |
| `overlays/default.nix` | Every patched or rebuilt nixpkgs package, each with why and when it can go |
| `overlays/expiry.nix` | The same "when it can go", as data CI can check |
| `pkgs/` | Packages nixpkgs doesn't have |

Nixpkgs fixes go in `overlays/default.nix`, never inline in a module. Host-specific settings go in
the host's files, never behind a `meta.hostname` check in a shared module.

Each overlay carries a comment saying why it exists and when to drop it, and a matching entry in
`overlays/expiry.nix`: either `nixpkgsAbove "<package>" "<version>"` (expired once every nixpkgs it
is applied to, `nixpkgs` and `unstable`, has a newer version) or `manual "<what to look for>"` (not
checkable, never reported). `nix flake check` fails if an overlay has no entry or an entry has no
overlay, so a patch can't land without a removal condition. When a flake update makes a condition
true, its PR gets a comment (`.github/scripts/overlay-expiry.sh`) naming the overlay to remove.

</details>

## Updates

Every flake input is updated in its own pull request, so a broken input blocks only itself.
`flake-update.yml` runs nightly (or on demand): it updates each input in a scratch lock and, for
the ones that moved, opens or refreshes `flake-update/<input>` as `bot-cecil[bot]`, at most eight
at a time. The pull request is written the way Renovate writes one (an update table, a rebase
box, the `stop-updating` label) because [Clarence](https://github.com/coredev-uk/clarence) rules on
it as on Renovate's, and nothing else merges it:

- Clarence holds an input until its locked commit has aged (48 h for `nixpkgs` and `unstable`, none
  for my own repositories, 72 h for the rest), then merges one update at a time, and waits for
  `evaluate`, `flake-checker`, `atlas` and `poseidon` to pass on `main` before the next. A merge
  that breaks `main` is reverted. The policy is `policy-nixos.json` in
  [home-ops](https://github.com/coredev-uk/home-ops/blob/main/docs/renovate-and-clarence.md).
- `hosts.yml` builds each update (poseidon only when its system changes), pushes it to the binary
  cache, and comments how every host's closure changes: the packages that changed version and the
  closure's size, against main's build.
- The same pull request says which overlays the update lets go (above).

A hand-made pull request (`nix flake update <input>` on a branch) gets Clarence's card but is never
merged on its own; merge it with `@bot-clarence merge` once its checks pass.

## Bootstrap

Clone the repo, run `nix develop` then `./install-with-disk`.

<details>
<summary>Installing NixOS with Disko</summary>

Boot the NixOS installer, clone this repository, enter the dev shell, then run:

```sh
nix develop
./install-with-disk atlas
```

Destructive. For `atlas`, Disko wipes the WD_BLACK SN770 (by `/dev/disk/by-id/`, see
`hosts/atlas/disks.nix`) and creates GPT, an unencrypted `/boot` ESP, a LUKS container
`cryptroot` and btrfs subvolumes. Install Windows on the other NVMe first for dual boot. Expect
the LUKS passphrase prompt during install and at boot.

The installer runs Disko, installs the flake configuration, then copies this repository to
`/mnt/home/<user>/.dotfiles`.

Secure Boot uses Lanzaboote. The installer creates sbctl keys at `/mnt/var/lib/sbctl` before
`nixos-install`; firmware enrollment is manual. After the first boot, run:

```sh
sudo sbctl status
sudo sbctl enroll-keys --microsoft
sudo nixos-rebuild switch --flake ~/.dotfiles#atlas
sudo sbctl verify
```

Then reboot into firmware setup and enable Secure Boot. `--microsoft` keeps Microsoft keys (Windows
11 dual boot, firmware option ROMs). On ASUS boards set Secure Boot `OS Type` to `Windows UEFI Mode`;
without a setup-mode option, erase the Platform Key instead of clearing all keys. Old keys under
`/etc/secureboot` must be migrated first:

```sh
sudo sbctl setup --migrate
```

</details>

<details>
<summary>Setting up athena (Windows and NixOS-WSL)</summary>

athena is atlas's Windows install on the other drive: gaming first, plus Sona's Windows build
tools. Linux is `nixosConfigurations.athena` and `paul@athena` (NixOS-WSL). Windows config is in
`hosts/athena/windows`:

| File | What it describes |
| :--- | :--- |
| `gaming.winget`, `dev.winget` | Apps, registry settings and Sona's build tools (WinGet configurations) |
| `winutil.json` | The WinUtil debloat, run once with `-Debloat` |
| `default.nix` | The home files, rendered from the Linux modules (git, ssh and the shell from `paul@athena`; Wintty, Vicinae, VS Code, fonts) and laid out by Windows folder |
| `shell.nix`, `zen.nix` | PowerShell's profile from zsh's settings; atlas's Zen for Windows |
| `apply.ps1` | Builds the above in WSL and puts it all in place |

On a fresh stock Windows 11: sign in, install Proton Pass and enable its SSH agent (Settings → SSH
agent), and install the Wintty sponsor build from wintty.io. Then, from any Nix (another WSL
distro, or atlas), build the distribution and install it from an elevated PowerShell:

```sh
nix build .#nixosConfigurations.athena.config.system.build.tarballBuilder
sudo ./result/bin/nixos-wsl-tarball-builder   # writes nixos.wsl
```

```powershell
wsl --install --from-file nixos.wsl --name NixOS
wsl --set-default NixOS
```

In NixOS, clone this repository to `~/.dotfiles` and run `nh home switch`. Then apply Windows'
half, elevated, the first time with `-Debloat` (WinUtil's tweaks and app removals). `-GamingOnly`
leaves the development tools out; `-Test` shows what has drifted:

```powershell
powershell -ExecutionPolicy Bypass -File \\wsl.localhost\NixOS\home\paul\.dotfiles\hosts\athena\windows\apply.ps1 -Debloat
```

What winget can't install is listed at the top of `gaming.winget`. Zen gets atlas's setup
(`zen.nix`) once it has a profile: start it once, close it, apply again.

</details>

<details>
<summary>Setting up hermes (Raspberry Pi 4)</summary>

hermes is a Raspberry Pi 4 with a PoE+ HAT on the IoT VLAN: Home Assistant's Bluetooth proxy
([btproxy](https://github.com/yuzi-co/btproxy), the ESPHome API on port 6053, open to Home
Assistant's address only). Its kernel, firmware and boot loader come from
[nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi), whose cache has the kernel built.

1. Run the `Hosts` workflow by hand on main and download the `hermes-sd-image` artifact from
   hermes' job.
2. Write it to the SD card:

   ```sh
   unzip hermes-sd-image.zip
   zstdcat nixos-image-rpi4-kernel.img.zst | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
   ```

3. Boot it on a switch port whose native network is the IoT VLAN, reserve its address in UniFi,
   and SSH in as paul (atlas's key). From then on it follows main each morning, like atlas.
4. In Home Assistant, add an ESPHome device at hermes' address, port 6053, with the key from
   `ssh hermes sudo cat /var/lib/btproxy/api.key`, and set the proxy's Bluetooth scanning mode to
   Active.

</details>

## Credits

Built on others' configurations, notably [jnsgruk/nixos-config](https://github.com/jnsgruk/nixos-config).

## Licence

Licensed under the MIT License ([LICENSE](LICENSE)).
