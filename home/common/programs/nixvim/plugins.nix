{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      # Auto-detect indentation
      sleuth.enable = true;

      # Snacks utilities
      snacks = {
        enable = true;
        settings = {
          lazygit.enabled = true;
          bigfile.enabled = true;
          notifier.enabled = true;
          git.enabled = true;
          gitbrowse.enabled = true;
          scroll.enabled = true;
          indent = {
            enabled = true;
            indent.only_scope = true;
          };
          statuscolumn.enabled = true;
        };
      };
    };

    # Extra plugins not managed by nixvim modules
    extraPlugins = with pkgs.vimPlugins; [
      yuck-vim
    ];
  };
}
