//@ pragma UseQApplication
// (tray context menus are platform menus, which need a QApplication)

import Quickshell
import qs.modules

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
