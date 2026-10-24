import QtQuick
import Quickshell.Services.Greetd

// The greeter's password check: a greetd login for `user`, one conversation per attempt.
AuthContext {
    id: root

    checking: Greetd.state === GreetdState.Authenticating

    onSubmitted: {
        if (!Greetd.available) {
            fail("greetd is not running");
            return;
        }
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
            root.fail("Incorrect password");
        }

        function onReadyToLaunch() {
            root.succeed();
        }

        function onError(error: string) {
            root.fail(`Login failed (${error})`);
        }
    }
}
