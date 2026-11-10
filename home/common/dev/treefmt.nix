_: {
  projectRootFile = "flake.nix";

  programs.deadnix.enable = true;
  programs.nixfmt.enable = true;
  programs.statix.enable = true;
  programs.shellcheck.enable = true;
  # The scripts are wrapped by writeShellApplication/writeShellScript, so they carry no shebang.
  settings.formatter.shellcheck.options = [
    "-s"
    "bash"
  ];
  programs.shfmt = {
    enable = true;
    # The scripts are tab-indented.
    indent_size = 0;
  };
}
