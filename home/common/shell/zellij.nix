{
  config,
  lib,
  meta,
  pkgs,
  ...
}:
let
  # ANSI colour numbers, so zellij follows the terminal palette (Ghostty's) instead of its fixed
  # 256-colour theme. 0 black, 2 green, 3 yellow, 6 cyan, 7 white, 8 bright black, 15 bright white.
  component = base: background: emphasis: {
    inherit base background;
    emphasis_0 = builtins.elemAt emphasis 0;
    emphasis_1 = builtins.elemAt emphasis 1;
    emphasis_2 = builtins.elemAt emphasis 2;
    emphasis_3 = builtins.elemAt emphasis 3;
  };
  # Key hints/highlights yellow; secondary slot (and new-tab button) bright black, then green.
  emphasis = [
    3
    8
    2
    3
  ];

  # Linux: Alt (passes through Ghostty). macOS: Cmd, which Ghostty releases (../programs/ghostty)
  # and reports via the kitty keyboard protocol; Option stays free for typing (# is Option+3, UK).
  mod = if meta.isDarwin then "Super" else "Alt";

  # Tab/pane keys differ per platform: macOS owns Cmd+Tab, Cmd+H, Cmd+Q (so Quit is Linux-only).
  # The Cmd set mirrors Ghostty's tabs and splits.
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

  # Alt+F/B page, Alt+C leaves; macOS uses Esc and plain keys (Cmd+C is copy).
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

    themes.terminal.themes.terminal = {
      text_unselected = component 7 0 emphasis;
      text_selected = component 15 0 emphasis;
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
      simplified_ui = true;

      # Kitty Unicode placeholders (U=1) are rejected by zellij (zellij-org/zellij#5530), so omp
      # images vanish; make omp use ordinary placements.
      env.PI_NO_KITTY_PLACEHOLDERS = "1";
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

              bind "${mod} t" { NewTab; }
              bind "${mod} Shift r" { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "${mod} w" { CloseFocus; }
              ${lib.concatMapStrings (
                n: ''bind "${mod} ${toString n}" { GoToTab ${toString n}; }'' + "\n"
              ) (lib.range 1 9)}
              // ${mod}+D side by side, ${mod}+Shift+D stacked
              bind "${mod} d" { NewPane "Right"; }
              bind "${mod} Shift d" { NewPane "Down"; }

              ${platformNormalBinds}
          }

          renametab {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
          }

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

  # Start zellij in every interactive terminal shell and exit with it. Inlined: HM's integration
  # runs `zellij setup --generate-auto-start` per shell (~35ms). Skipped for `-c` commands: GUI
  # apps probe `$SHELL -l -i -c printenv`, and zellij there opens its own window.
  programs.zsh.initContent = lib.mkOrder 200 ''
    if [[ "$TERM" != "dumb" && -z "$ZELLIJ" && -z "$ZSH_EXECUTION_STRING" && -t 0 && -t 1 ]]; then
      ${lib.getExe config.programs.zellij.package}
      exit
    fi
  '';

  # 0.46 shows the "Welcome" wizard every session until setup is approved/declined; record its
  # "never show" answer. Patched in place because zellij rewrites the file.
  home.activation.zellijSkipSetup =
    let
      dataDir =
        if meta.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/org.Zellij-Contributors.Zellij"
        else
          "${config.xdg.dataHome}/zellij";
      jq = lib.getExe pkgs.jq;
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      state=${lib.escapeShellArg "${dataDir}/desktop_integration.json"}
      if ! ${jq} -e '.flags | index("SetupNeverShow")' "$state" >/dev/null 2>&1; then
        tmp=$(mktemp)
        ${jq} '.flags = ((.flags // []) + ["SetupNeverShow"] | unique)' "$state" >"$tmp" 2>/dev/null \
          || echo '{"flags":["SetupNeverShow"]}' >"$tmp"
        run mkdir -p "$(dirname "$state")"
        run mv "$tmp" "$state"
      fi
    '';
}
