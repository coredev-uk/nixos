{ self, pkgs, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  m = theme.meridian;
  syn = m.syntax;
in
{
  programs.nixvim = {
    # Meridian through base16-nvim: it paints the editor, syntax, Treesitter, LSP and diff groups
    # from 16 slots, and highlightOverride below corrects the places where base16's conventions
    # clash with Meridian's world rules (variables in base08 red, cream window separators).
    colorschemes.base16 = {
      enable = true;
      colorscheme = {
        base00 = m.ground;
        base01 = m.plate;
        base02 = m.selection;
        # Comments, hints and NonText: the terminal's bright black, tuned for 3.5:1 on the ground.
        base03 = m.terminal.bright.black;
        base04 = m.text2;
        base05 = m.text;
        # Meridian has no enamel lighter than text, so the "lighter foreground" slots repeat it.
        base06 = m.text;
        base07 = m.text;
        base08 = m.alert;
        base09 = syn.constant;
        base0A = m.gilt;
        base0B = syn.string;
        base0C = syn.type;
        base0D = syn.function;
        base0E = syn.keyword;
        base0F = syn.special;
      };
    };

    # Applied after every plugin's setup. Plugins (gitsigns, blink.cmp, noice, snacks, mini,
    # which-key) only define their groups with `default = true` links, so these win.
    highlightOverride = {
      # Grounds: the cursor line and floats sit on plate, selection is the selection ground.
      CursorLine.bg = m.plate;
      CursorColumn.bg = m.plate;
      ColorColumn.bg = m.plate;
      Visual.bg = m.selection;
      VisualNOS.bg = m.selection;
      LineNr.fg = m.muted;
      CursorLineNr = {
        fg = m.gilt;
        bg = m.plate;
        bold = true;
      };
      # The GUI cursor matches the terminal's gilt cursor.
      Cursor = {
        fg = m.ground;
        bg = m.gilt;
      };
      MatchParen = {
        fg = m.gilt;
        bold = true;
      };
      VertSplit.fg = m.rule;
      WinSeparator.fg = m.rule;

      NormalFloat = {
        fg = m.text;
        bg = m.plate;
      };
      FloatBorder = {
        fg = m.rule;
        bg = m.plate;
      };
      FloatTitle = {
        fg = m.text;
        bg = m.plate;
        bold = true;
      };
      FloatFooter = {
        fg = m.text2;
        bg = m.plate;
      };

      Pmenu = {
        fg = m.text;
        bg = m.plate;
      };
      PmenuSel = {
        fg = m.text;
        bg = m.selection;
        bold = true;
      };
      PmenuKind = {
        fg = m.series1;
        bg = m.plate;
      };
      PmenuExtra = {
        fg = m.text2;
        bg = m.plate;
      };
      PmenuMatch = {
        fg = m.gilt;
        bg = m.plate;
        bold = true;
      };
      PmenuMatchSel = {
        fg = m.gilt;
        bg = m.selection;
        bold = true;
      };
      PmenuSbar.bg = m.plate;
      PmenuThumb.bg = m.rule;

      StatusLine = {
        fg = m.text2;
        bg = m.plate;
      };
      StatusLineNC = {
        fg = m.muted;
        bg = m.plate;
      };
      TabLine = {
        fg = m.muted;
        bg = m.plate;
      };
      TabLineFill.bg = m.plate;
      TabLineSel = {
        fg = m.gilt;
        bg = m.ground;
      };
      WildMenu = {
        fg = m.ground;
        bg = m.gilt;
      };

      # Search is gilt-tinted; the match under the cursor is the one solid gilt mark.
      Search = {
        fg = m.gilt;
        bg = m.hover;
      };
      CurSearch = {
        fg = m.ground;
        bg = m.gilt;
        bold = true;
      };
      IncSearch.link = "CurSearch";

      # Red is for errors only: base16 puts variables, statements, tags and macros in base08.
      Identifier.fg = m.text;
      TSVariable.fg = m.text;
      TSVariableBuiltin = {
        fg = syn.special;
        italic = true;
      };
      Statement.fg = syn.keyword;
      Repeat.fg = syn.keyword;
      Exception.fg = syn.keyword;
      TSException.fg = syn.keyword;
      Character.fg = syn.string;
      TSCharacter.fg = syn.string;
      Macro.fg = syn.special;
      TSFuncMacro.fg = syn.special;
      TSConstMacro.fg = syn.special;
      TSNamespace.fg = syn.type;
      TSTag.fg = syn.function;
      Debug.fg = m.caution;
      WarningMsg.fg = m.caution;
      Underlined = {
        fg = m.link;
        underline = true;
      };
      # Commas and semicolons recede instead of taking a categorical hue.
      Delimiter.fg = m.text2;
      TSPunctDelimiter.fg = m.text2;
      # base16 paints types in base0A; gilt stays for here/selection/search, so types take the
      # syntax cyan. @type and @type.builtin link to the TS groups.
      Type.fg = syn.type;
      TSType.fg = syn.type;
      TSTypeBuiltin = {
        fg = syn.type;
        italic = true;
      };
      StorageClass.fg = syn.type;
      Structure.fg = syn.type;
      Typedef.fg = syn.type;

      DiagnosticError.fg = m.alert;
      DiagnosticWarn.fg = m.caution;
      DiagnosticInfo.fg = m.link;
      DiagnosticHint.fg = m.ok;
      DiagnosticOk.fg = m.ok;
      DiagnosticUnderlineError = {
        sp = m.alert;
        undercurl = true;
      };
      DiagnosticUnderlineWarn = {
        sp = m.caution;
        undercurl = true;
      };
      DiagnosticUnderlineInfo = {
        sp = m.link;
        undercurl = true;
      };
      DiagnosticUnderlineHint = {
        sp = m.ok;
        undercurl = true;
      };
      DiagnosticUnderlineOk = {
        sp = m.ok;
        undercurl = true;
      };
      DiagnosticDeprecated = {
        sp = m.muted;
        strikethrough = true;
      };
      LspSignatureActiveParameter = {
        fg = m.gilt;
        bold = true;
      };

      Added.fg = m.ok;
      Changed.fg = m.caution;
      Removed.fg = m.alert;
      # Without these gitsigns falls back to base16's GitGutter groups (changes in link blue).
      GitSignsAdd.fg = m.ok;
      GitSignsChange.fg = m.caution;
      GitSignsChangedelete.fg = m.caution;
      GitSignsDelete.fg = m.alert;
      GitSignsTopdelete.fg = m.alert;

      # blink.cmp: the menu and docs are floats, so they take the float border.
      BlinkCmpMenuBorder.link = "FloatBorder";
      BlinkCmpDocBorder.link = "FloatBorder";
      BlinkCmpSignatureHelpBorder.link = "FloatBorder";
      BlinkCmpLabelMatch.link = "PmenuMatch";

      # noice draws the cmdline popup on Normal with an info-blue border by default.
      NoiceCmdlinePopup.link = "NormalFloat";
      NoiceCmdlinePopupBorder.link = "FloatBorder";
      NoiceCmdlinePopupBorderSearch.link = "FloatBorder";
      NoiceCmdlinePopupTitle.link = "FloatTitle";
      NoiceCmdlineIcon.fg = m.gilt;
      NoiceCmdlineIconSearch.fg = m.gilt;

      SnacksInputBorder.link = "FloatBorder";
      SnacksInputTitle.link = "FloatTitle";
      SnacksInputIcon.fg = m.gilt;
      SnacksPickerMatch = {
        fg = m.gilt;
        bold = true;
      };
      SnacksPickerPrompt.fg = m.gilt;
      SnacksPickerSelected.fg = m.gilt;
      SnacksIndent.fg = m.rule;
      SnacksIndentScope.fg = m.muted;
      SnacksDashboardKey.fg = m.gilt;

      # mini.statusline links its mode chips to diff groups, which base16 renders as dark tints.
      MiniStatuslineModeNormal = {
        fg = m.gilt;
        bg = m.selection;
        bold = true;
      };
      MiniStatuslineModeInsert = {
        fg = m.ground;
        bg = m.ok;
        bold = true;
      };
      MiniStatuslineModeVisual = {
        fg = m.ground;
        bg = m.series4;
        bold = true;
      };
      MiniStatuslineModeReplace = {
        fg = m.ground;
        bg = m.caution;
        bold = true;
      };
      MiniStatuslineModeCommand = {
        fg = m.ground;
        bg = m.link;
        bold = true;
      };
      MiniStatuslineModeOther = {
        fg = m.ground;
        bg = m.series3;
        bold = true;
      };
      MiniStatuslineDevinfo = {
        fg = m.text2;
        bg = m.hover;
      };
      MiniStatuslineFileinfo = {
        fg = m.text2;
        bg = m.hover;
      };
      MiniStatuslineFilename = {
        fg = m.text2;
        bg = m.plate;
      };
      MiniStatuslineInactive = {
        fg = m.muted;
        bg = m.plate;
      };

      # mini.icons hues follow the terminal ANSI colours; its red would otherwise borrow
      # DiagnosticError for ordinary file types.
      MiniIconsAzure.fg = m.terminal.bright.blue;
      MiniIconsBlue.fg = m.terminal.normal.blue;
      MiniIconsCyan.fg = m.terminal.normal.cyan;
      MiniIconsGreen.fg = m.terminal.normal.green;
      MiniIconsGrey.fg = m.text2;
      MiniIconsOrange.fg = m.caution;
      MiniIconsPurple.fg = m.terminal.normal.magenta;
      MiniIconsRed.fg = m.series3;
      MiniIconsYellow.fg = m.gilt;
    };

    plugins = {
      # UI enhancements
      noice = {
        enable = true;
      };

      # Web devicons
      web-devicons.enable = true;

      # Syntax-highlighted completion menu
      colorful-menu = {
        enable = true;
        settings = {
          ls = {
            lua_ls.arguments_hl = "@comment";
            ts_ls.extra_info_hl = "@comment";
          };
          fallback_highlight = "@variable";
          max_width = 60;
        };
      };

      # Mini modules
      mini = {
        enable = true;
        modules = {
          basics = { };
          statusline = { };
          icons = { };
        };
      };
    };
  };
}
