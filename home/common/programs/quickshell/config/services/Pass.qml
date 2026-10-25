pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Proton Pass through the quickshell-pass helper (scripts/pass.sh). Only titles, vaults and the
// non-secret details are held here, in memory; secrets go from pass-cli straight to the clipboard.
Singleton {
    id: root

    // Until the first status check neither signed in nor out.
    property bool known: false
    property bool signedIn: false
    property string account: ""
    // [{ share, id, title, type, vault }] by title.
    property var items: []
    property bool loaded: false
    // Why the items couldn't be listed; cleared by the next successful refresh.
    property string error: ""
    // "share/id" -> { type, username, email, urls, hasPassword, hasTotp, hasNote, primary }
    property var details: ({})
    // Sign-in page of a pending web login.
    property string loginUrl: ""

    readonly property bool loading: statusProc.running || listProc.running
    readonly property bool signingIn: loginProc.running

    signal copied(string what, int clearAfter)
    signal failed(string message)
    signal signInPageReady(string url)
    signal signedInNow

    function key(item: var): string {
        return `${item.share}/${item.id}`;
    }

    // Lists right away when signed in before; a failure then checks whether the session is gone.
    // Nothing runs while a web login is pending (the helper refuses anyway, see scripts/pass.sh):
    // the window just shows the waiting state until signedInNow.
    function refresh() {
        if (signingIn)
            return;
        if (signedIn)
            listProc.running = true;
        else
            statusProc.running = true;
    }

    function signIn() {
        if (signingIn)
            return;
        error = "";
        loginUrl = "";
        loginProc.cancelled = false;
        loginProc.running = true;
    }

    function cancelSignIn() {
        if (!signingIn)
            return;
        loginProc.cancelled = true;
        loginProc.signal(15);
    }

    function signOut() {
        logoutProc.running = true;
    }

    // One item at a time: the latest request wins over any still waiting.
    function loadDetails(item: var) {
        if (!item || details[key(item)] !== undefined)
            return;
        if (detailsProc.running) {
            detailsProc.pending = item;
            return;
        }
        detailsProc.item = item;
        detailsProc.command = ["quickshell-pass", "details", item.share, item.id];
        detailsProc.running = true;
    }

    // `what` names the field in the confirmation, e.g. "password".
    function copySecret(item: var, field: string, what: string) {
        copyProc.what = what;
        copyProc.command = ["quickshell-pass", "copy", item.share, item.id, field];
        copyProc.running = true;
    }

    // Usernames, emails and addresses are already here and not secret.
    function copyText(value: string, what: string) {
        Quickshell.clipboardText = value;
        copied(what, 0);
    }

    function lastLine(text: string): string {
        return text.trim().split("\n").pop() ?? "";
    }

    Process {
        id: statusProc

        // After a failed list: only find out whether the session is gone, don't list again.
        property bool recheck: false

        command: ["quickshell-pass", "status"]
        stdout: StdioCollector {
            id: statusOut
        }
        stderr: StdioCollector {
            id: statusErr
        }
        onExited: code => {
            const recheck = statusProc.recheck;
            statusProc.recheck = false;
            if (code !== 0) {
                root.error = root.lastLine(statusErr.text) || "Couldn't reach Proton Pass";
                return;
            }
            const status = JSON.parse(statusOut.text);
            root.known = true;
            root.signedIn = status.signedIn;
            root.account = status.account ?? "";
            if (status.signedIn) {
                if (!recheck)
                    listProc.running = true;
            } else {
                root.error = "";
                root.items = [];
                root.details = {};
                root.loaded = false;
            }
        }
    }

    Process {
        id: listProc

        command: ["quickshell-pass", "list"]
        stdout: StdioCollector {
            id: listOut
        }
        stderr: StdioCollector {
            id: listErr
        }
        onExited: code => {
            if (code === 0) {
                root.items = JSON.parse(listOut.text);
                root.loaded = true;
                root.error = "";
                return;
            }
            // Signed out elsewhere, or locked: the status check tells which.
            root.error = root.lastLine(listErr.text) || "Couldn't load your items";
            statusProc.recheck = true;
            statusProc.running = true;
        }
    }

    Process {
        id: loginProc

        // Set by cancelSignIn, so the killed login isn't reported as a failure.
        property bool cancelled: false

        command: ["quickshell-pass", "login"]
        stdout: SplitParser {
            onRead: line => {
                const message = JSON.parse(line);
                if (message.url) {
                    root.loginUrl = message.url;
                    root.signInPageReady(message.url);
                }
            }
        }
        stderr: StdioCollector {
            id: loginErr
        }
        onExited: code => {
            root.loginUrl = "";
            if (code === 0) {
                root.signedIn = true;
                root.signedInNow();
                statusProc.running = true;
            } else if (!cancelled) {
                root.error = root.lastLine(loginErr.text) || "Sign-in failed";
            }
        }
    }

    Process {
        id: logoutProc

        command: ["quickshell-pass", "logout"]
        stderr: StdioCollector {
            id: logoutErr
        }
        onExited: code => {
            if (code !== 0)
                root.failed(root.lastLine(logoutErr.text) || "Couldn't sign out");
            root.signedIn = false;
            statusProc.running = true;
        }
    }

    Process {
        id: detailsProc

        property var item
        property var pending: null

        stdout: StdioCollector {
            id: detailsOut
        }
        stderr: StdioCollector {
            id: detailsErr
        }
        onExited: code => {
            if (code === 0)
                root.details = Object.assign({}, root.details, {
                    [root.key(item)]: JSON.parse(detailsOut.text)
                });
            else
                root.failed(root.lastLine(detailsErr.text) || "Couldn't load the item");
            const next = pending;
            pending = null;
            root.loadDetails(next);
        }
    }

    Process {
        id: copyProc

        property string what

        stdout: StdioCollector {
            id: copyOut
        }
        stderr: StdioCollector {
            id: copyErr
        }
        onExited: code => {
            if (code === 0)
                root.copied(what, JSON.parse(copyOut.text).clearAfter);
            else
                root.failed(root.lastLine(copyErr.text) || `Couldn't copy the ${what}`);
        }
    }
}
