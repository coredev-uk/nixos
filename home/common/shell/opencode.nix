{ inputs, meta, ... }:

{
  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;

    settings = {
      theme = "system";

      plugin = [
        "opencode-antigravity-auth@latest"
        "opencode-openai-codex-auth@latest"
      ];

    };
  };
}
