import QtQuick
import Quickshell.Services.Greetd

// The greeter's password check: a greetd login for `user`, one conversation per attempt.
AuthContext {
    id: root

    checking: Greetd.state === GreetdState.Authenticating

    // Quickshell cancels the greetd session after a rejected password, but greetd's PAM worker
    // has already exited, so the cancel comes back as an error ("unable to send message:
    // Connection refused"). That error belongs to the attempt already reported as rejected.
    property bool rejected: false

    onSubmitted: {
        if (!Greetd.available) {
            fail("greetd is not running");
            return;
        }
        rejected = false;
        Greetd.createSession(user);
    }

    Connections {
        target: Greetd

        // Only the password prompt is answered; anything else is shown as is.
        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool) {
            if (responseRequired)
                Greetd.respond(root.currentText);
            else
                root.notice(message, error);
        }

        function onAuthFailure(message: string) {
            root.rejected = true;
            root.fail("Incorrect password");
        }

        function onReadyToLaunch() {
            root.succeed();
        }

        function onError(error: string) {
            if (!root.rejected)
                root.fail(`Login failed (${error})`);
        }
    }
}
