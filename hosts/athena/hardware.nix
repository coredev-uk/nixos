_: {
  nixpkgs.hostPlatform = "x86_64-linux";

  # Windows' NVIDIA driver (/usr/lib/wsl/lib) for CUDA + Mesa D3D12, so WSLg renders on the RTX 3080.
  wsl.useWindowsDriver = true;
  hardware.graphics.enable = true;
}
