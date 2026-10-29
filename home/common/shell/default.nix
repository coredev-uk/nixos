{
  pkgs,
  self,
  lib,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./omp.nix
    ./fastfetch.nix
    ./nh.nix
    ./nix-index.nix
    ./ssh.nix
    ./zellij.nix
    ./zsh.nix
    ../programs/nixvim
  ]
  ++ lib.optional (!meta.isHeadless) ./git.nix
  ++ lib.optionals meta.isDesktop [
    ./xdg.nix
  ];

  programs = {
    eza =
      let
        m = theme.meridian;
        term = m.terminal;
        fg = c: { foreground = c; };
      in
      {
        enable = true;
        git = true;
        extraOptions = [
          "--group"
          "--group-directories-first"
        ];
        # Directories blue and executables green as in ls; metadata columns stay in the
        # secondary legends so the names lead. Red only for broken links and root.
        theme = {
          colourful = true;
          filekinds = {
            normal = fg m.text;
            directory = fg term.normal.blue;
            symlink = fg term.normal.cyan;
            pipe = fg term.normal.magenta;
            block_device = fg m.caution;
            char_device = fg m.caution;
            socket = fg term.normal.magenta;
            special = fg term.normal.magenta;
            executable = fg term.normal.green;
            mount_point = fg term.bright.blue;
          };
          perms = {
            user_read = fg m.text;
            user_write = fg m.gilt;
            user_execute_file = fg term.normal.green;
            user_execute_other = fg term.normal.green;
            group_read = fg m.text2;
            group_write = fg m.text2;
            group_execute = fg m.text2;
            other_read = fg m.muted;
            other_write = fg m.muted;
            other_execute = fg m.muted;
            special_user_file = fg term.normal.magenta;
            special_other = fg term.normal.magenta;
            attribute = fg m.muted;
          };
          size = {
            major = fg m.text2;
            minor = fg m.text2;
            number_byte = fg m.text2;
            number_kilo = fg m.text2;
            number_mega = fg m.text;
            number_giga = fg m.gilt;
            number_huge = fg m.gilt;
            unit_byte = fg m.muted;
            unit_kilo = fg m.muted;
            unit_mega = fg m.muted;
            unit_giga = fg m.muted;
            unit_huge = fg m.muted;
          };
          users = {
            user_you = fg m.text2;
            user_root = fg m.alert;
            user_other = fg m.caution;
            group_yours = fg m.text2;
            group_other = fg m.muted;
            group_root = fg m.alert;
          };
          links = {
            normal = fg term.normal.cyan;
            multi_link_file = fg term.bright.cyan;
          };
          git = {
            new = fg m.ok;
            modified = fg m.gilt;
            deleted = fg m.alert;
            renamed = fg term.normal.cyan;
            typechange = fg term.normal.magenta;
            ignored = fg m.muted;
            conflicted = fg m.caution;
          };
          git_repo = {
            branch_main = fg m.text2;
            branch_other = fg term.normal.magenta;
            git_clean = fg m.ok;
            git_dirty = fg m.gilt;
          };
          security_context = {
            colon = fg m.muted;
            user = fg m.text2;
            role = fg term.normal.magenta;
            typ = fg m.muted;
            range = fg term.normal.magenta;
          };
          file_type = {
            image = fg m.series3;
            video = fg m.series3;
            music = fg m.series2;
            lossless = fg m.series2;
            crypto = fg m.muted;
            document = fg m.text;
            compressed = fg m.series4;
            temp = fg m.muted;
            compiled = fg term.normal.cyan;
            source = fg m.series1;
          };
          punctuation = fg m.muted;
          date = fg m.text2;
          inode = fg m.muted;
          blocks = fg m.muted;
          header = fg m.text;
          octal = fg term.normal.cyan;
          flags = fg term.normal.magenta;
          symlink_path = fg term.bright.cyan;
          control_char = fg m.caution;
          broken_symlink = fg m.alert;
          broken_path_overlay = fg m.muted;
        };
      };
    # fzf binary for fzf-tab. No zsh integration: its Ctrl-R would replace atuin's.
    # The colours land in FZF_DEFAULT_OPTS, which fzf-tab also reads.
    fzf = {
      enable = true;
      enableZshIntegration = false;
      colors = with theme.meridian; {
        fg = text;
        bg = ground;
        "fg+" = text;
        "bg+" = hover;
        gutter = ground;
        hl = gilt;
        "hl+" = giltHover;
        info = text2;
        border = rule;
        separator = rule;
        scrollbar = rule;
        label = text2;
        query = text;
        prompt = gilt;
        pointer = gilt;
        marker = gilt;
        spinner = text2;
        header = text2;
      };
    };
    home-manager.enable = true;
  };

}
