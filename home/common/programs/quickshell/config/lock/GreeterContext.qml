import QtQuick
import Quickshell.Services.Greetd

// Password check via a greetd login for `user`, one conversation per attempt.
AuthContext {
    id: root

    checking: Greetd.state === GreetdState.Authenticating

    // After a rejected password Quickshell cancels the greetd session, but greetd's PAM worker has
    // already exited, so the cancel errors ("Connection refused"); that error belongs to the rejected attempt.
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
