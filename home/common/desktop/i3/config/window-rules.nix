# Command List:
# 'move', 'exec', 'exit', 'restart', 'reload'
# 'shmlog', 'debuglog', 'border', 'layout'
# 'append_layout', 'workspace', 'focus', 'kill', 'open'
# 'fullscreen', 'sticky', 'split', 'floating', 'mark'
# 'unmark', 'resize', 'rename', 'nop', 'scratchpad'
# 'swap', 'title_format', 'title_window_icon', 'mode', 'bar', 'gaps'

_: {
  commands = [
    # Floating window config
    {
      command = "floating enable";
      criteria = {
        window_role = "pop up|bubble|task_dialog|Preferences|page-info|Saves As|dialog|menu";
      };
    }
    {
      command = "floating enable";
      criteria = {
        instance = "org.gnome.*|nm-connection-editor|pavucontrol|com.saivert.pwvucontrol|pinentry-qt|.protonvpn-app-wrapped";
      };
    }
    {
      # 1Password Floating Windows
      command = "floating enable sticky";
      criteria = {
        title = "Quick Access|Unlock 1Password|Settings|^1Password$";
        class = "1Password";
      };
    }
    {
      # Enable floating for all Steam windows
      command = "floating enable";
      criteria = {
        class = "^steam$";
        instance = "^steamwebhelper$";
      };
    }
    {
      # Disable floating for the main Steam window
      command = "floating disable";
      criteria = {
        title = "^Steam$";
        class = "^steam$";
        instance = "^steamwebhelper$";
      };
    }
    {
      # Star Citizen Launcher
      command = "floating enable";
      criteria = {
        title = "^RSI Launcher$";
        class = "^rsi launcher.exe$";
      };
    }
    # Fullscreen Games
    {
      command = "floating disable";
      criteria = {
        class = "^starcitizen.exe$|steam_app_*";
      };
    }
    # Floating & Sticky windows
    {
      command = "floating enable sticky";
      criteria = {
        window_role = "Open Files|Open Folder|File Operation Progress";
      };
    }
    # Sticky windows
    {
      command = "sticky enable";
      criteria = {
        instance = "file_progress";
      };
    }
    {
      command = "sticky enable";
      criteria = {
        class = "info|Mate-color-select|gcolor2|timesup|QtPass|GtkFileChooserDialog";
      };
    }
    # Inhibit idle when there is a fullscreen app
    {
      command = "inhibit_idle fullscreen";
      criteria = {
        class = ".*";
      };
    }
  ];
}
