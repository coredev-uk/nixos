{ inputs, meta, ... }:
{
  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;
  };
}
