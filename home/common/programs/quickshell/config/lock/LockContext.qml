import QtQuick
import Quickshell.Services.Pam

// The lock screen's password check: PAM, against the quickshell-lock service.
AuthContext {
    id: root

    checking: pam.active

    onSubmitted: pam.start()

    PamContext {
        id: pam

        // /etc/pam.d/quickshell-lock, from security.pam.services in hosts/common/desktop/hyprland.nix.
        config: "quickshell-lock"

        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
            else
                root.notice(message, messageIsError);
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.succeed();
            else
                root.fail(result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password");
        }

        onError: error => root.fail(`Authentication unavailable (${PamError.toString(error)})`)
    }
}
