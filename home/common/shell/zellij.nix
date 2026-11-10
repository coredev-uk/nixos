{
  config,
  lib,
  meta,
  ...
}:
let
  # ANSI colour numbers, so zellij draws with the terminal's palette (Ghostty's, from
  # lib/theme) rather than fixed colours of its own; its built-in theme uses fixed 256-colour
  # values. 0 black (a step above the background), 2 green, 3 yellow, 6 cyan, 7 white,
  # 8 bright black, 15 bright white.
  component = base: background: emphasis: {
    inherit base background;
    emphasis_0 = builtins.elemAt emphasis 0;
    emphasis_1 = builtins.elemAt emphasis 1;
    emphasis_2 = builtins.elemAt emphasis 2;
    emphasis_3 = builtins.elemAt emphasis 3;
  };
  # Key hints and highlighted words in yellow; the secondary slot (also the new-tab button)
  # in bright black so it doesn't compete, then green. No magenta.
  emphasis = [
    3
    8
    2
    3
  ];

  # Linux binds on Alt, the modifier Ghostty passes through. macOS binds on Cmd, its own
  # modifier: Ghostty releases these keys (../programs/ghostty.nix) and reports them with the
  # kitty keyboard protocol, which zellij turns on. Option is left to type characters (# is
  # Option+3 on a UK layout).
  mod = if meta.isDarwin then "Super" else "Alt";

  # Tab cycling and pane focus/resize can't share keys across platforms: macOS owns Cmd+Tab
  # and Cmd+H, and Cmd+Q, so zellij's Quit is Linux-only. The Cmd set follows Ghostty's own
  # tabs and splits; Ctrl+Tab cycles tabs as in browsers.
  platformNormalBinds =
    if meta.isDarwin then
      ''
        bind "Ctrl Tab" "Super Shift ]" { GoToNextTab; }
        bind "Ctrl Shift Tab" "Super Shift [" { GoToPreviousTab; }
        bind "Super f" { SwitchToMode "EnterSearch"; SearchInput 0; }

        bind "Super ]" { FocusNextPane; }
        bind "Super [" { FocusPreviousPane; }
        bind "Super Alt Left" { MoveFocusOrTab "Left"; }
        bind "Super Alt Right" { MoveFocusOrTab "Right"; }
        bind "Super Alt Down" { MoveFocus "Down"; }
        bind "Super Alt Up" { MoveFocus "Up"; }
        bind "Super Ctrl Left" { Resize "Left"; }
        bind "Super Ctrl Right" { Resize "Right"; }
        bind "Super Ctrl Down" { Resize "Down"; }
        bind "Super Ctrl Up" { Resize "Up"; }
      ''
    else
      ''
        bind "Alt Tab" { GoToNextTab; }
        bind "Alt Shift Tab" { GoToPreviousTab; }
        bind "Alt x" { CloseFocus; }

        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
        bind "Alt j" "Alt Down" { MoveFocus "Down"; }
        bind "Alt k" "Alt Up" { MoveFocus "Up"; }
        bind "Ctrl Alt h" { Resize "Left"; }
        bind "Ctrl Alt l" { Resize "Right"; }
        bind "Ctrl Alt j" { Resize "Down"; }
        bind "Ctrl Alt k" { Resize "Up"; }
      '';

  # Scrollback paging on Alt+F/B and leaving with Alt+C; Cmd+C is copy on macOS, and Esc and
  # the plain keys cover it there.
  scrollBinds = ''
    bind "j" "Down" { ScrollDown; }
    bind "k" "Up" { ScrollUp; }
    bind "d" { HalfPageScrollDown; }
    bind "u" { HalfPageScrollUp; }
  ''
  + (
    if meta.isDarwin then
      ''
        bind "PageDown" "Right" "l" { PageScrollDown; }
        bind "PageUp" "Left" "h" { PageScrollUp; }
      ''
    else
      ''
        bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
        bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
        bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
      ''
  );
in
{
  programs.zellij = {
    enable = true;

    # New-style (0.42+) component theme.
    themes.terminal.themes.terminal = {
      text_unselected = component 7 0 emphasis;
      text_selected = component 15 0 emphasis;
      # The selected tab and the active mode are "here": dark on yellow.
      ribbon_selected = component 0 3 [
        0
        0
        0
        0
      ];
      ribbon_unselected = component 7 0 emphasis;
      table_title = component 3 0 emphasis;
      table_cell_selected = component 15 0 emphasis;
      table_cell_unselected = component 7 0 emphasis;
      list_selected = component 15 0 emphasis;
      list_unselected = component 7 0 emphasis;
      # The focused pane's frame is yellow; resting frames recede.
      frame_selected = component 3 0 emphasis;
      frame_unselected = component 8 0 emphasis;
      frame_highlight = component 6 0 emphasis;
      exit_code_success = component 2 0 emphasis;
      exit_code_error = component 1 0 emphasis;
      multiplayer_user_colors = {
        player_1 = 4;
        player_2 = 2;
        player_3 = 6;
        player_4 = 3;
        player_5 = 12;
        player_6 = 10;
        player_7 = 14;
        player_8 = 11;
        player_9 = 9;
        player_10 = 7;
      };
    };

    settings = {
      theme = "terminal";
      default_shell = "zsh";
      show_startup_tips = false;
      show_release_notes = false;
      ui.pane_frames.rounded_corners = true;
      # Plain separators in the tab and status bars instead of powerline triangles.
      simplified_ui = true;
    };

    extraConfig = ''
      keybinds clear-defaults=true {
          ${lib.optionalString (!meta.isDarwin) ''shared_except "locked" { bind "Alt q" { Quit; }; }''}
          locked {
              bind "${mod} g" { SwitchToMode "Normal"; }
          }

          normal {
              bind "${mod} g" { SwitchToMode "Locked"; }
              bind "${mod} o" { SwitchToMode "Session"; }
              bind "${mod} s" { SwitchToMode "Scroll"; }

              // tabs
              bind "${mod} t" { NewTab; }
              bind "${mod} Shift r" { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "${mod} w" { CloseFocus; }
              ${lib.concatMapStrings (
                n: ''bind "${mod} ${toString n}" { GoToTab ${toString n}; }'' + "\n"
              ) (lib.range 1 9)}
              // panes / splits
              // ${mod}+D = vertical split (side by side), ${mod}+Shift+D = horizontal split (stacked)
              bind "${mod} d" { NewPane "Right"; }
              bind "${mod} Shift d" { NewPane "Down"; }

              ${platformNormalBinds}
          }

          renametab {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
          }

          // Keyboard scrollback (mouse wheel scrolling always works regardless of keybinds).
          scroll {
              bind "${mod} s" "Esc" { SwitchToMode "Normal"; }
              bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
              bind "e" { EditScrollback; SwitchToMode "Normal"; }
              ${scrollBinds}
          }
          search {
              bind "${mod} s" { SwitchToMode "Normal"; }
              bind "n" { Search "down"; }
              bind "p" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "w" { SearchToggleOption "Wrap"; }
              bind "o" { SearchToggleOption "WholeWord"; }
              ${scrollBinds}
          }
          entersearch {
              bind "Esc" { SwitchToMode "Scroll"; }
              ${lib.optionalString (!meta.isDarwin) ''bind "Alt c" { SwitchToMode "Scroll"; }''}
              bind "Enter" { SwitchToMode "Search"; }
          }

          // Session mode: detach + the built-in plugin launchers.
          session {
              bind "${mod} o" { SwitchToMode "Normal"; }
              bind "${mod} s" { SwitchToMode "Scroll"; }
              bind "d" { Detach; }
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "p" {
                  LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "a" {
                  LaunchOrFocusPlugin "zellij:about" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "l" {
                  LaunchOrFocusPlugin "zellij:layout-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
          }
      }
    '';
  };

  # Start zellij in every interactive shell outside it, and close the shell when zellij exits.
  # Inlined instead of HM's integration, which runs `zellij setup --generate-auto-start` in
  # every shell (~35ms) to print this same check.
  programs.zsh.initContent = lib.mkOrder 200 ''
    if [[ "$TERM" != "dumb" && -z "$ZELLIJ" ]]; then
      ${lib.getExe config.programs.zellij.package}
      exit
    fi
  '';
}
