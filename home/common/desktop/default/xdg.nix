{ inputs, meta, ... }:
let
  inherit ((import ./file-associations.nix { inherit inputs meta; })) associations;
in
{
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = associations;
    };
  };
}
