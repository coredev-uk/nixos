_: {
  projectRootFile = "flake.nix";

  programs.deadnix.enable = true;
  programs.nixfmt.enable = true;
  programs.statix.enable = true;
  programs.shellcheck.enable = true;
  # Scripts are wrapped, so no shebang.
  settings.formatter.shellcheck.options = [
    "-s"
    "bash"
  ];
  programs.shfmt = {
    enable = true;
    # Scripts are tab-indented.
    indent_size = 0;
  };
}
