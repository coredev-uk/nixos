{
  programs.nixvim.plugins = {
    # File explorer
    neo-tree = {
      enable = true;
      settings = {
        filesystem.hijack_netrw_behavior = "open_current";
      };
    };

    # Fuzzy finder
    telescope = {
      enable = true;
    };
  };
}
