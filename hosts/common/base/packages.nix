{ pkgs, ... }:
{
  basePackages = with pkgs; [
    binutils
    cabextract
    curl
    file
    git
    jq
    killall
    lsof
    nfs-utils
    ntfs3g
    pciutils
    ripgrep
    rsync
    sbctl
    tpm2-tss
    tree
    unzip
    usbutils
    vim
    wget
  ];
}
