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

## Bootstrap Guide

Clone the repo, run `nix develop` then ./install-with-disk

<details>
<summary>Installing NixOS with Disko</summary>

Boot the NixOS installer, clone this repository, enter the dev shell, then run:

```sh
nix develop
./install-with-disk atlas
```

This is destructive. For `atlas`, Disko currently targets `/dev/nvme0n1` and will
wipe it before creating the GPT, ESP, LUKS, and btrfs subvolume layout.

The installer runs Disko, installs the `atlas` flake configuration, then copies
this repository to `/mnt/home/<user>/.dotfiles`.

</details>
