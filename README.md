<img src="assets/logo.svg" alt="" width="100" align="left">

### NixOS Configuration

[![Flake Checks](https://img.shields.io/github/actions/workflow/status/coredev-uk/nixos/nix-check.yml?branch=main&label=flake%20checks)](https://github.com/coredev-uk/nixos/actions/workflows/nix-check.yml)
[![Hosts](https://img.shields.io/github/actions/workflow/status/coredev-uk/nixos/hosts.yml?branch=main&label=hosts)](https://github.com/coredev-uk/nixos/actions/workflows/hosts.yml)
[![Last commit](https://img.shields.io/github/last-commit/coredev-uk/nixos.svg)](https://github.com/coredev-uk/nixos/commits)

Core's Nix flake for NixOS and macOS: one configuration for every machine, from disk layout to desktop.

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
|  `athena`  |      Windows       | Desktop |   N/A    |   N/A   |

</details>

## Bootstrap

Clone the repo, run `nix develop` then `./install-with-disk`.

<details>
<summary>Installing NixOS with Disko</summary>

Boot the NixOS installer, clone this repository, enter the dev shell, then run:

```sh
nix develop
./install-with-disk atlas
```

This is destructive. For `atlas`, Disko targets the WD_BLACK SN770 by its
`/dev/disk/by-id/` path (see `hosts/atlas/disks.nix`) and will wipe it before
creating the GPT, ESP, LUKS, and btrfs subvolume layout. Windows
should be installed on the other NVMe first if this is a dual-boot system.

The installer runs Disko, installs the `atlas` flake configuration, then copies
this repository to `/mnt/home/<user>/.dotfiles`.

Disk encryption is handled by Disko. The `atlas` layout creates an unencrypted
`/boot` ESP and a LUKS container named `cryptroot` for the NixOS btrfs root and
subvolumes. Expect to enter the LUKS passphrase during install and at boot.

Secure Boot is configured with Lanzaboote. The installer creates sbctl signing
keys in the target system at `/mnt/var/lib/sbctl` before `nixos-install` so
Lanzaboote can sign boot files, but firmware enrollment is intentionally manual.
After the first successful boot into the installed system, run:

```sh
sudo sbctl status
sudo sbctl enroll-keys --microsoft
sudo nixos-rebuild switch --flake ~/.dotfiles#atlas
sudo sbctl verify
```

Then reboot into firmware setup and enable Secure Boot. The `--microsoft` flag
keeps Microsoft keys enrolled, which is useful for Windows 11 dual boot and some
firmware option ROMs. On ASUS desktop boards, this may require setting Secure
Boot `OS Type` to `Windows UEFI Mode`; if there is no explicit setup-mode option,
erase the existing Platform Key instead of clearing all Secure Boot keys. If you
already have old keys under `/etc/secureboot`, migrate them to sbctl's default
location first with:

```sh
sudo sbctl setup --migrate
```

</details>

## Credits

This would not be possible without other people's configurations, notably
[jnsgruk/nixos-config](https://github.com/jnsgruk/nixos-config), which was a great help at getting going.

## Licence

Licensed under the MIT License ([LICENSE](LICENSE)).
