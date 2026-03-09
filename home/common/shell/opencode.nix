{ inputs, meta, ... }:
{

  xdg.configFile."opencode/tui.json".source = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "system";
  };

  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;

    settings = {
      plugin = [
        "opencode-openai-codex-auth@latest"
      ];
    };
  };
}
