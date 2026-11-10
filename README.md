# Core's NixOS Configuration Files

[![Flake Checks](https://github.com/coredev-uk/nixos/actions/workflows/nix-check.yml/badge.svg)](https://github.com/coredev-uk/nixos/actions/workflows/nix-check.yml)

These are my NixOS config files. I recently moved from Arch Linux using i3wm and
Hyprland to Nix. I am new at this approach and find it great to work with. This
would not be possible without the help of other user configuration files,
notably [this repo](https://github.com/jnsgruk/nixos-config) by jnsgruk; this
was a great help at getting going.

## Device Estate

|  Hostname  |         OS         | Device  |        WM        |   Status    |
| :--------: | :----------------: | :-----: | :--------------: | :---------: |
|  `atlas`   |       NixOS        | Desktop | Hyperland        |   Working   |
| `poseidon` | macOS (nix-darwin) | Laptop  |       N/A        |   Working   |
|  `athena`  |      Windows       | Desktop |       N/A        |     N/A     |

## Password Manager

`passwordManager` in `flake.nix` is the one switch: `"1password"` (the default) or
`"proton-pass"`. Every module reads it as `meta.passwordManager`; rebuild atlas
(NixOS and Home Manager) and poseidon after changing it.

| | 1Password | Proton Pass |
| --- | --- | --- |
| SSH agent | the app's agent, keys listed in `~/.config/1Password/ssh/agent.toml` | `pass-cli ssh-agent start` as a user service (systemd on atlas, launchd on poseidon), socket `~/.ssh/proton-pass-agent.sock`; it serves every SSH key item of the signed-in account |
| Commit signing | `op-ssh-sign` | git's `ssh-keygen` through that agent |
| App | `programs._1password-gui`, polkit unlock, started hidden by Hyprland | `proton-pass` (Home Manager on atlas, the Homebrew cask on poseidon), not started at login |
| Browser | 1Password extension and the `custom_allowed_browsers` entry for Zen | the Proton Pass extension, already installed with either |

Before switching to Proton Pass, import the SSH keys into it with `pass-cli item
create ssh-key import` (the public keys in `home/common/shell/ssh.nix` and
`home/common/shell/git.nix` stay valid only for the same keys) and sign in with
`pass-cli login` (the bar's Proton Pass window does it on atlas); the agent
service retries every 30 seconds until then. 1Password's polkit unlock and its
browser allow-list have no Proton Pass counterpart here: Proton's app and
extension unlock with their own settings. The items other repositories read are
covered in coredev-uk/home-ops's `.github/README.md`.

## Bootstrap Guide

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
