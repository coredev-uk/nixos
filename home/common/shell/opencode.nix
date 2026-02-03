{ inputs, meta, ... }:

{
  home.file.".config/opencode/oh-my-opencode.json".text = ''
    {
      "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
      "agents": {
        "sisyphus": {
          "model": "anthropic/claude-sonnet-4-5"
        },
        "oracle": {
          "model": "github-copilot/gpt-5.2",
          "variant": "high"
        },
        "librarian": {
          "model": "opencode/big-pickle"
        },
        "explore": {
          "model": "anthropic/claude-haiku-4-5"
        },
        "multimodal-looker": {
          "model": "google/gemini-3-flash"
        },
        "prometheus": {
          "model": "anthropic/claude-opus-4-5",
          "variant": "max"
        },
        "metis": {
          "model": "anthropic/claude-opus-4-5",
          "variant": "max"
        },
        "momus": {
          "model": "github-copilot/gpt-5.2",
          "variant": "medium"
        },
        "atlas": {
          "model": "anthropic/claude-sonnet-4-5"
        }
      },
      "categories": {
        "visual-engineering": {
          "model": "google/gemini-3-pro"
        },
        "ultrabrain": {
          "model": "github-copilot/gpt-5.2-codex",
          "variant": "xhigh"
        },
        "artistry": {
          "model": "google/gemini-3-pro",
          "variant": "max"
        },
        "quick": {
          "model": "anthropic/claude-haiku-4-5"
        },
        "unspecified-low": {
          "model": "anthropic/claude-sonnet-4-5"
        },
        "unspecified-high": {
          "model": "anthropic/claude-sonnet-4-5"
        },
        "writing": {
          "model": "google/gemini-3-flash"
        }
      }
    }

  '';

  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;

    settings = {
      plugin = [
        "oh-my-opencode@latest"
        "opencode-antigravity-auth@latest"
      ];

      provider = {
        google = {
          name = "Google";
          models = {
            antigravity-gemini-3-pro = {
              name = "Gemini 3 Pro (Antigravity)";
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingLevel = "low";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };

            antigravity-gemini-3-flash = {
              name = "Gemini 3 Flash (Antigravity)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                minimal = {
                  thinkingLevel = "minimal";
                };
                low = {
                  thinkingLevel = "low";
                };
                medium = {
                  thinkingLevel = "medium";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };

            antigravity-claude-sonnet-4-5 = {
              name = "Claude Sonnet 4.5 (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };

            antigravity-claude-sonnet-4-5-thinking = {
              name = "Claude Sonnet 4.5 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };

            antigravity-claude-opus-4-5-thinking = {
              name = "Claude Opus 4.5 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
