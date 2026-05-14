{ pkgs, ... }:
{
  basePackages = with pkgs; [
    bat
    binutils
    cabextract
    curl
    eza
    file
    git
    jq
    killall
    lsof
    nfs-utils
    ntfs3g
    pciutils
    polkit_gnome
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
