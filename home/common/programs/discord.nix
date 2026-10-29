{
  inputs,
  pkgs,
  self,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  m = theme.meridian;

  # Meridian for Discord, as Vencord Quick CSS (nixcord writes local theme files only for
  # Vesktop/Equibop). Only Discord's colour and font variables are set, never its hashed
  # component classes, so the theme survives Discord's frequent class renames. The variables
  # are redeclared on the theme classes because Discord declares them there, and !important
  # because the visual refresh does so with higher specificity (`.visual-refresh.theme-dark`).
  quickCss = ''
    :root,
    .theme-dark,
    .theme-darker,
    .theme-midnight,
    .theme-light {
      --font-primary: "${theme.fonts.shell.name}", sans-serif !important;
      --font-display: "${theme.fonts.shell.name}", sans-serif !important;
      --font-headline: "${theme.fonts.shell.name}", sans-serif !important;
      --font-code: "${theme.fonts.monospace.name}", monospace !important;

      /* Grounds: the chat on ground, the channel and member lists as plates, the server rail
         and window frame inset; popouts, menus and modals are plates. */
      --background-primary: ${m.ground} !important;
      --background-secondary: ${m.plate} !important;
      --background-secondary-alt: ${m.inset} !important;
      --background-tertiary: ${m.inset} !important;
      --background-floating: ${m.plate} !important;
      --background-nested-floating: ${m.inset} !important;
      --background-accent: ${m.rule} !important;
      --background-base-low: ${m.ground} !important;
      --background-base-lower: ${m.plate} !important;
      --background-base-lowest: ${m.inset} !important;
      --background-surface-high: ${m.plate} !important;
      --background-surface-higher: ${m.plate} !important;
      --background-surface-highest: ${m.hover} !important;
      --bg-base-primary: ${m.ground} !important;
      --bg-base-secondary: ${m.plate} !important;
      --bg-base-tertiary: ${m.inset} !important;
      --bg-surface-overlay: ${m.plate} !important;
      --bg-surface-raised: ${m.plate} !important;
      --chat-background-default: ${m.ground} !important;
      --home-background: ${m.ground} !important;
      --card-background-default: ${m.plate} !important;
      --modal-background: ${m.plate} !important;
      --modal-footer-background: ${m.inset} !important;
      --input-background: ${m.inset} !important;
      --channeltextarea-background: ${m.plate} !important;

      /* Hover and pressed rows take the hover ground; the row you are on gets a gilt tint. */
      --background-modifier-hover: ${m.hover} !important;
      --background-modifier-active: ${m.rule} !important;
      --background-modifier-selected: ${m.gilt}1a !important;
      --background-modifier-accent: ${m.rule} !important;
      --background-message-hover: ${m.hover}80 !important;
      --bg-mod-faint: ${m.hover}80 !important;
      --bg-mod-subtle: ${m.hover} !important;
      --bg-mod-strong: ${m.rule} !important;

      --border-faint: ${m.rule} !important;
      --border-subtle: ${m.rule} !important;
      --border-normal: ${m.rule} !important;
      --border-strong: ${m.selection} !important;

      /* Legends */
      --text-normal: ${m.text} !important;
      --text-default: ${m.text} !important;
      --text-strong: ${m.text} !important;
      --text-secondary: ${m.text2} !important;
      --text-subtle: ${m.text2} !important;
      --text-muted: ${m.text2} !important;
      --text-link: ${m.link} !important;
      --text-brand: ${m.gilt} !important;
      --text-positive: ${m.ok} !important;
      --text-warning: ${m.caution} !important;
      --text-danger: ${m.alert} !important;
      --header-primary: ${m.text} !important;
      --header-secondary: ${m.text2} !important;
      --channels-default: ${m.text2} !important;
      --channel-icon: ${m.text2} !important;
      --channel-text-area-placeholder: ${m.muted} !important;
      --textbox-markdown-syntax: ${m.muted} !important;
      --interactive-normal: ${m.text2} !important;
      --interactive-hover: ${m.text} !important;
      --interactive-active: ${m.text} !important;
      --interactive-muted: ${m.muted} !important;
      --interactive-text-default: ${m.text2} !important;
      --interactive-text-hover: ${m.text} !important;
      --interactive-text-active: ${m.text} !important;
      --icon-default: ${m.text2} !important;
      --icon-strong: ${m.text} !important;
      --icon-subtle: ${m.text2} !important;
      --icon-muted: ${m.muted} !important;
      --icon-primary: ${m.text} !important;
      --icon-secondary: ${m.text2} !important;

      /* Gilt: Discord's brand colour, so primary buttons, toggles, focus and mentions. */
      --brand-260: ${m.giltHover} !important;
      --brand-360: ${m.giltHover} !important;
      --brand-400: ${m.giltHover} !important;
      --brand-430: ${m.giltHover} !important;
      --brand-460: ${m.giltHover} !important;
      --brand-500: ${m.gilt} !important;
      --brand-530: ${m.gilt} !important;
      --brand-560: ${m.gilt} !important;
      --brand-600: ${m.gilt} !important;
      --brand-630: ${m.gilt} !important;
      --brand-660: ${m.gilt} !important;
      --brand-experiment: ${m.gilt} !important;
      --brand-experiment-360: ${m.giltHover} !important;
      --brand-experiment-400: ${m.giltHover} !important;
      --brand-experiment-500: ${m.gilt} !important;
      --brand-experiment-560: ${m.gilt} !important;
      --brand-experiment-600: ${m.gilt} !important;
      --bg-brand: ${m.gilt} !important;
      --button-filled-brand-background: ${m.gilt} !important;
      --button-filled-brand-background-hover: ${m.giltHover} !important;
      --button-filled-brand-background-active: ${m.gilt} !important;
      --button-filled-brand-text: ${m.ground} !important;
      --button-filled-brand-text-hover: ${m.ground} !important;
      --control-brand-foreground: ${m.gilt} !important;
      --control-brand-foreground-new: ${m.gilt} !important;
      --focus-primary: ${m.gilt} !important;
      --mention-foreground: ${m.gilt} !important;
      --mention-background: ${m.gilt}26 !important;
      --background-mentioned: ${m.gilt}1a !important;
      --background-mentioned-hover: ${m.gilt}26 !important;

      /* State */
      --status-positive: ${m.ok} !important;
      --status-positive-background: ${m.ok} !important;
      --status-warning: ${m.caution} !important;
      --status-warning-background: ${m.caution} !important;
      --status-danger: ${m.alert} !important;
      --status-danger-background: ${m.alert} !important;
      --button-danger-background: ${m.alert} !important;
      --button-danger-background-hover: ${m.alert} !important;

      --scrollbar-auto-thumb: ${m.rule} !important;
      --scrollbar-auto-track: transparent !important;
      --scrollbar-thin-thumb: ${m.rule} !important;
      --scrollbar-thin-track: transparent !important;
    }
  '';
in
{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Docs: https://flameflag.github.io/nixcord/
  programs.nixcord = {
    enable = true;

    discord = {
      enable = true;
      krisp.enable = true;
      vencord.enable = true;
    };

    inherit quickCss;

    config = {
      useQuickCss = true;
      plugins = {
        clearUrls.enable = true;
        disableCallIdle.enable = true;

        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;

        messageLogger.enable = true;
        mutualGroupDms.enable = true;
        openInApp.enable = true;

        shikiCodeblocks.enable = true;
        sortFriendRequests.enable = true;

        translate.enable = true;
        validUser.enable = true;

        youtubeAdblock.enable = true;
      };
    };
  };
}
