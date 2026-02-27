{ inputs, meta, ... }:

{
  programs.opencode = {
    enable = true;

    settings = {
      theme = "system";

      plugin = [
        "opencode-antigravity-auth@latest"
        "opencode-openai-codex-auth@latest"
      ];

    };
  };
}
