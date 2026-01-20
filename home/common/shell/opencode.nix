{ inputs, meta, ... }:
{
  opencode = {
    enable = true;
    package = inputs.opencode.packages.${meta.system}.default;
    settings = {
      plugin = [ "opencode-gemini-auth@latest" ];
      provider = {
        google = {
          options = {
            projectId = " gen-lang-client-0793465664";
          };
        };
      };
    };
  };

}
