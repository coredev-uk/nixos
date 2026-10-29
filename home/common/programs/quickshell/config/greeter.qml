import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs.common
import qs.lock

// greetd greeter, run by `quickshell-greeter` inside a greeter-only Hyprland
// (hosts/common/desktop/greeter.nix). Same faces as the lock screen, minus today's events and
// the music: there is no user session yet to show them from. Once logged in it hands
// greetd the session command and quits; the wrapper then closes the compositor so greetd can
// start the session.
ShellRoot {
    id: shell

    // Set by the wrapper: who logs in, and the session to start as JSON
    // ({"command": [...], "environment": ["NAME=value", ...]}).
    readonly property var session: JSON.parse(Quickshell.env("QS_GREETER_SESSION") ?? "{}")

    GreeterContext {
        id: greeterContext

        user: Quickshell.env("QS_GREETER_USER") ?? ""
        hasUserSession: false

        onFinished: Greetd.launch(shell.session.command ?? [], shell.session.environment ?? [], true)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.ground
            WlrLayershell.namespace: "greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LockSurface {
                anchors.fill: parent
                context: greeterContext
            }
        }
    }
}
