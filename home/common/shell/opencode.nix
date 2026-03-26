{ inputs, meta, ... }:
{
  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;

    settings = {
      plugin = [ "@ex-machina/opencode-anthropic-auth" ];
    };
  };
}
