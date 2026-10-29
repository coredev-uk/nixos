{ self, pkgs, ... }:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;
  term = m.terminal;
in
{
  programs.btop = {
    enable = true;
    settings.color_theme = "meridian";
  };

  # Box outlines stay on the rule so the graphs carry the colour. Graphs use the categorical
  # series; only temperature, a real state, runs ok -> caution -> alert.
  xdg.configFile."btop/themes/meridian.theme".text = ''
    theme[main_bg]="${m.ground}"
    theme[main_fg]="${m.text}"
    theme[title]="${m.text}"
    theme[hi_fg]="${m.gilt}"
    theme[selected_bg]="${m.selection}"
    theme[selected_fg]="${m.text}"
    theme[inactive_fg]="${m.muted}"
    theme[graph_text]="${m.text2}"
    theme[meter_bg]="${m.rule}"
    theme[proc_misc]="${m.text2}"

    theme[cpu_box]="${m.rule}"
    theme[mem_box]="${m.rule}"
    theme[net_box]="${m.rule}"
    theme[proc_box]="${m.rule}"
    theme[div_line]="${m.rule}"

    theme[temp_start]="${m.ok}"
    theme[temp_mid]="${m.caution}"
    theme[temp_end]="${m.alert}"

    theme[cpu_start]="${m.series1}"
    theme[cpu_mid]="${m.series4}"
    theme[cpu_end]="${m.series3}"

    theme[free_start]="${m.series2}"
    theme[free_mid]="${term.normal.cyan}"
    theme[free_end]="${term.bright.green}"

    theme[cached_start]="${m.series1}"
    theme[cached_mid]="${term.bright.blue}"
    theme[cached_end]="${m.series4}"

    theme[available_start]="${m.series4}"
    theme[available_mid]="${term.bright.magenta}"
    theme[available_end]="${m.series3}"

    theme[used_start]="${m.series3}"
    theme[used_mid]="${m.series4}"
    theme[used_end]="${m.series1}"

    theme[download_start]="${m.series1}"
    theme[download_mid]="${term.bright.blue}"
    theme[download_end]="${m.series4}"

    theme[upload_start]="${m.series2}"
    theme[upload_mid]="${term.normal.cyan}"
    theme[upload_end]="${m.series1}"

    theme[process_start]="${m.series1}"
    theme[process_mid]="${m.series4}"
    theme[process_end]="${m.series3}"
  '';
}
