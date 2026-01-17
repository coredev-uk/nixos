{ inputs, lib, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disks.nix { inherit lib; })

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    # inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ../common/hardware/bluetooth.nix
  ];

  hardware.nvidia = {
    # Force use the proprietary Nvidia drivers
    open = false;

    # Required for proper refresh rate handling afaik
    forceFullCompositionPipeline = true;

    # Wayland
    modesetting.enable = true;

    powerManagement = {
      enable = true;
      finegrained = false;
    };

    nvidiaSettings = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
