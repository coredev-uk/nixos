_: {
  nixpkgs.hostPlatform = "x86_64-linux";

  # The GPU through WSL: Windows' NVIDIA driver (/usr/lib/wsl/lib) for CUDA and Mesa's D3D12
  # driver, so WSLg windows (a Linux Sona build) render on the RTX 3080.
  wsl.useWindowsDriver = true;
  hardware.graphics.enable = true;
}
