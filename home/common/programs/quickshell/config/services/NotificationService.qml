pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification daemon: keeps every notification until it is dismissed (the centre's history)
// and decides which of them show as popups. Do Not Disturb survives restarts in the state dir;
// the count and DnD are also published for the lock screen, a separate instance
// (services/NotificationCount.qml).
Singleton {
    id: root

    // Entries, newest first: { notification, time, popup }. Plain arrays, as ScriptModel wants.
    property var entries: []
    readonly property var popups: entries.filter(entry => entry.popup)
    readonly property int count: entries.length
    readonly property bool dnd: state.dnd
    // Older popups beyond this only stay in the centre.
    readonly property int maxPopups: 5
    readonly property string statusPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-notifications.json`

    // Asks the bell on `screen` to toggle the centre.
    signal centerToggled(string screen)

    function toggleDnd() {
        state.dnd = !state.dnd;
    }

    function clearAll() {
        dismiss(entries);
    }

    // The app a notification is labelled with, and grouped under in the centre.
    function appName(notification: Notification): string {
        return notification?.appName || DesktopEntries.byId(notification?.desktopEntry ?? "")?.name || "Notification";
    }

    function clearApp(app: string) {
        dismiss(entries.filter(entry => appName(entry.notification) === app));
    }

    function dismiss(list: var) {
        // dismiss() removes the entry through its closed signal.
        for (const entry of list.slice())
            entry.notification.dismiss();
    }

    function hidePopup(entry: Entry) {
        entry.popup = false;
        // Transient notifications are only meant to be seen, not kept.
        if (entry.notification.transient)
            entry.notification.expire();
    }

    // Clicking a notification: its default action if it has one, else it just leaves the popups.
    function activate(entry: Entry) {
        const action = entry.notification.actions.find(action => action.identifier === "default");
        if (action)
            action.invoke();
        else
            hidePopup(entry);
    }

    function add(notification: Notification) {
        // After a config reload the server announces the notifications it kept again; those
        // have already been seen.
        const popup = !notification.lastGeneration && (!dnd || notification.urgency === NotificationUrgency.Critical);
        // Transient ones are only meant to be seen: untracked, one that can't show now is dropped.
        if (notification.transient && !popup)
            return;
        notification.tracked = true;
        entries = [entryComponent.createObject(root, {
                notification,
                popup
            }), ...entries];
        for (const extra of popups.slice(maxPopups))
            extra.popup = false;
    }

    function remove(entry: Entry) {
        entries = entries.filter(other => other !== entry);
        entry.destroy();
    }

    // A replacement (same id) updates the notification in place: bring it back to the top and
    // show it again, like a new one.
    function refresh(entry: Entry) {
        entry.time = Date.now();
        entry.popup = !dnd || entry.notification.urgency === NotificationUrgency.Critical;
        entries = [entry, ...entries.filter(other => other !== entry)];
    }

    // Replaces whatever a previous run left behind, even when nothing changes.
    Component.onCompleted: publish.restart()
    onCountChanged: publish.restart()
    onDndChanged: publish.restart()

    component Entry: QtObject {
        id: entry

        required property Notification notification
        property double time: Date.now()
        property bool popup: false

        readonly property Connections connections: Connections {
            target: entry.notification

            function onClosed() {
                root.remove(entry);
            }
            function onSummaryChanged() {
                root.refresh(entry);
            }
            function onBodyChanged() {
                root.refresh(entry);
            }
        }
    }

    Component {
        id: entryComponent

        Entry {}
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notification => root.add(notification)
    }

    FileView {
        path: Quickshell.statePath("notifications.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: state

            property bool dnd: false
        }
    }

    // Coalesces the count changes of Clear all into one write.
    Timer {
        id: publish

        interval: 100
        onTriggered: status.setText(JSON.stringify({
            count: root.count,
            dnd: root.dnd
        }))
    }

    FileView {
        id: status

        path: root.statusPath
        blockLoading: false
        preload: false
        printErrors: false
    }

    IpcHandler {
        target: "notifications"

        // Opens the centre under the bell of the focused monitor.
        function toggle(): void {
            root.centerToggled(Hyprland.focusedMonitor?.name ?? "");
        }
        function toggleDnd(): void {
            root.toggleDnd();
        }
        function clear(): void {
            root.clearAll();
        }
    }
}
