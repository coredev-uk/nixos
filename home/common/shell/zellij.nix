_:
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

    enableZshIntegration = true;
    exitShellOnExit = true;

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
          shared_except "locked" {
              bind "Alt q" { Quit; }
          }

          locked {
              bind "Alt g" { SwitchToMode "Normal"; }
          }

          normal {
              bind "Alt g" { SwitchToMode "Locked"; }
              bind "Alt o" { SwitchToMode "Session"; }
              bind "Alt s" { SwitchToMode "Scroll"; }

              // tabs
              bind "Alt t" { NewTab; }
              bind "Alt Shift r" { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "Alt w" { CloseFocus; }
              bind "Alt Tab" { GoToNextTab; }
              bind "Alt Shift Tab" { GoToPreviousTab; }
              bind "Alt 1" { GoToTab 1; }
              bind "Alt 2" { GoToTab 2; }
              bind "Alt 3" { GoToTab 3; }
              bind "Alt 4" { GoToTab 4; }
              bind "Alt 5" { GoToTab 5; }
              bind "Alt 6" { GoToTab 6; }
              bind "Alt 7" { GoToTab 7; }
              bind "Alt 8" { GoToTab 8; }
              bind "Alt 9" { GoToTab 9; }

              // panes / splits
              // Alt+D = vertical split (side by side), Alt+Shift+D = horizontal split (stacked)
              bind "Alt d" { NewPane "Right"; }
              bind "Alt Shift d" { NewPane "Down"; }
              bind "Alt x" { CloseFocus; }

              // pane focus / resize
              bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
              bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
              bind "Alt j" "Alt Down" { MoveFocus "Down"; }
              bind "Alt k" "Alt Up" { MoveFocus "Up"; }
              bind "Ctrl Alt h" { Resize "Left"; }
              bind "Ctrl Alt l" { Resize "Right"; }
              bind "Ctrl Alt j" { Resize "Down"; }
              bind "Ctrl Alt k" { Resize "Up"; }
          }

          renametab {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
          }

          // Keyboard scrollback (mouse wheel scrolling always works regardless of keybinds).
          scroll {
              bind "Alt s" "Esc" { SwitchToMode "Normal"; }
              bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
              bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
              bind "e" { EditScrollback; SwitchToMode "Normal"; }
          }
          search {
              bind "Alt s" { SwitchToMode "Normal"; }
              bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
              bind "n" { Search "down"; }
              bind "p" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "w" { SearchToggleOption "Wrap"; }
              bind "o" { SearchToggleOption "WholeWord"; }
          }
          entersearch {
              bind "Alt c" "Esc" { SwitchToMode "Scroll"; }
              bind "Enter" { SwitchToMode "Search"; }
          }

          // Session mode: detach + the built-in plugin launchers.
          session {
              bind "Alt o" { SwitchToMode "Normal"; }
              bind "Alt s" { SwitchToMode "Scroll"; }
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
}
