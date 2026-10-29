{ self, pkgs, ... }:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;
  term = m.terminal;

  # Colours as RGB triplets, the form zellij's own themes use: "#c9a24f" -> [ 201 162 79 ].
  rgb =
    hex:
    map pkgs.lib.fromHexString [
      (builtins.substring 1 2 hex)
      (builtins.substring 3 2 hex)
      (builtins.substring 5 2 hex)
    ];
  # base/background plus the four emphasis slots every component takes.
  component = base: background: emphasis: {
    base = rgb base;
    background = rgb background;
    emphasis_0 = rgb (builtins.elemAt emphasis 0);
    emphasis_1 = rgb (builtins.elemAt emphasis 1);
    emphasis_2 = rgb (builtins.elemAt emphasis 2);
    emphasis_3 = rgb (builtins.elemAt emphasis 3);
  };
  # Key hints and highlighted words: gilt first, then the calm categorical hues.
  emphasis = [
    m.gilt
    m.link
    m.ok
    m.series4
  ];
in
{
  programs.zellij = {
    enable = true;

    # New-style (0.42+) component theme.
    themes.meridian.themes.meridian = {
      text_unselected = component m.text m.ground emphasis;
      text_selected = component m.text m.selection emphasis;
      # The selected tab (and the active mode key) is "here": ground on gilt. Everything
      # else sits on plate, so the bar reads as one quiet strip.
      ribbon_selected = component m.ground m.gilt [
        m.inset
        m.ground
        m.ground
        m.ground
      ];
      ribbon_unselected = component m.text2 m.plate emphasis;
      table_title = component m.gilt m.ground emphasis;
      table_cell_selected = component m.text m.selection emphasis;
      table_cell_unselected = component m.text2 m.ground emphasis;
      list_selected = component m.text m.selection emphasis;
      list_unselected = component m.text2 m.ground emphasis;
      # The focused pane's frame is gilt; resting frames recede to the rule.
      frame_selected = component m.gilt m.ground emphasis;
      frame_unselected = component m.rule m.ground emphasis;
      frame_highlight = component m.caution m.ground emphasis;
      exit_code_success = component m.ok m.ground emphasis;
      exit_code_error = component m.alert m.ground emphasis;
      multiplayer_user_colors = {
        player_1 = rgb m.series1;
        player_2 = rgb m.series2;
        player_3 = rgb m.series3;
        player_4 = rgb m.series4;
        player_5 = rgb term.normal.cyan;
        player_6 = rgb term.bright.blue;
        player_7 = rgb term.bright.green;
        player_8 = rgb term.bright.magenta;
        player_9 = rgb term.bright.cyan;
        player_10 = rgb m.fill;
      };
    };

    enableZshIntegration = true;
    exitShellOnExit = true;

    settings = {
      theme = "meridian";
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
