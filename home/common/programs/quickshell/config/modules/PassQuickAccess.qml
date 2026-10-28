import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.services
import qs.widgets

// Proton Pass quick access (`quickshell ipc -c bar call pass toggle`), laid out like 1Password's:
// search every vault from the focused monitor, Enter opens the item's actions (copy username,
// password, one-time code or API keys, open the login's website in the browser). The copy and
// open keys also work straight from the list on the highlighted item. There is no "Open in
// Proton Pass": the desktop app's protonpass:// links only cover sign-in, and the web app signs
// in every time.
// Secrets go from pass-cli to the clipboard inside the quickshell-pass helper (scripts/pass.sh),
// which clears them again after 45s; services/Pass.qml holds only titles and non-secret details.
Scope {
    id: root

    readonly property int rowHeight: 40
    readonly property int visibleRows: 8

    property bool open: false
    property string screenName: ""
    property string query: ""
    // The selection follows the item, not its position, while results re-rank.
    property string selectedKey: ""
    // Confirmation or failure under the list.
    property string notice: ""
    property bool noticeIsError: false

    readonly property var results: search(Pass.items, query, Pass.details)
    readonly property int selected: Math.max(0, results.findIndex(item => Pass.key(item) === selectedKey))
    readonly property var current: results[selected] ?? null
    // The item whose actions are showing (Enter on a result), else null for the list.
    property var openedItem: null
    property int actionIndex: 0
    // What the copy and open keys act on: the open item, else the highlighted result.
    readonly property var target: openedItem ?? current
    readonly property var actions: actionsOf(openedItem, Pass.details)

    function detailsOf(item: var): var {
        return item ? Pass.details[Pass.key(item)] ?? null : null;
    }

    // The secret Ctrl+Shift+C copies; known from the type before the details arrive.
    function primaryFieldOf(item: var): string {
        if (!item)
            return "";
        const details = detailsOf(item);
        if (details)
            return details.primary;
        return {
            login: "password",
            wifi: "password",
            credit_card: "number",
            ssh_key: "private_key",
            note: "note"
        }[item.type] ?? "";
    }

    function userOf(item: var): string {
        const details = detailsOf(item);
        return details ? details.username || details.email : "";
    }

    function urlOf(item: var): string {
        return detailsOf(item)?.urls[0] ?? "";
    }

    // The open item's menu, in 1Password's order and with its keys; `gap` sets the browser apart.
    function actionsOf(item: var, details: var): var {
        if (!item)
            return [];
        const info = details[Pass.key(item)] ?? null;
        const list = [];
        const user = info ? info.username || info.email : "";
        if (user !== "")
            list.push({
                id: "user",
                icon: info.username ? Icons.accountOutline : Icons.email,
                label: info.username ? "Copy username" : "Copy email",
                shortcut: "Ctrl+C"
            });
        const primary = primaryFieldOf(item);
        if (primary !== "")
            list.push({
                id: "primary",
                icon: primary === "note" ? Icons.noteText : Icons.key,
                label: `Copy ${fieldName(primary)}`,
                shortcut: "Ctrl+Shift+C"
            });
        if (info?.hasTotp)
            list.push({
                id: "totp",
                icon: Icons.twoFactor,
                label: "Copy one-time code",
                shortcut: "Ctrl+Alt+C"
            });
        // One row per API key field, named by the field (numbered when names repeat). The
        // confirmation says which one was copied when there are several.
        const apiKeys = info?.apiKeys ?? [];
        for (const field of apiKeys) {
            const same = apiKeys.filter(other => other.name === field.name);
            const name = same.length > 1 ? `${field.name} (${same.indexOf(field) + 1})` : field.name;
            list.push({
                id: `apiKey:${field.index}`,
                icon: Icons.keyChain,
                label: "Copy API key",
                detail: name,
                what: apiKeys.length > 1 ? name : "API key",
                shortcut: ""
            });
        }
        const url = info?.urls[0] ?? "";
        if (url !== "")
            list.push({
                id: "url",
                icon: Icons.web,
                label: "Open in browser",
                detail: url.replace(/^https?:\/\//, "").replace(/\/$/, ""),
                shortcut: "Alt+Enter",
                gap: list.length > 0
            });
        return list;
    }

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function show() {
        screenName = Hyprland.focusedMonitor?.name ?? "";
        query = "";
        selectedKey = "";
        openedItem = null;
        notice = "";
        open = true;
        Pass.refresh();
    }

    function close() {
        open = false;
    }

    // Every word has to match: the title ranks above the vault, username and website, and a
    // scattered match in the title ("gthb" for GitHub) still counts, last.
    function search(items: var, text: string, details: var): var {
        const words = text.toLowerCase().split(/\s+/).filter(word => word !== "");
        if (words.length === 0)
            return items;
        const scored = [];
        items.forEach((item, index) => {
            const title = item.title.toLowerCase();
            const extra = details[Pass.key(item)];
            const other = [item.vault, extra?.username, extra?.email, ...(extra?.urls ?? [])].join(" ").toLowerCase();
            let score = 0;
            for (const word of words) {
                const at = title.indexOf(word);
                if (at === 0)
                    score += 4;
                else if (at > 0)
                    score += /[\s\-_.@:/]/.test(title[at - 1]) ? 3 : 2;
                else if (other.includes(word))
                    score += 1;
                else if (scattered(title, word))
                    score += 0.5;
                else
                    return;
            }
            scored.push({
                item,
                index,
                score
            });
        });
        return scored.sort((a, b) => b.score - a.score || a.index - b.index).map(entry => entry.item);
    }

    function scattered(haystack: string, needle: string): bool {
        let from = 0;
        for (const c of needle) {
            from = haystack.indexOf(c, from) + 1;
            if (from === 0)
                return false;
        }
        return true;
    }

    function move(delta: int) {
        const item = results[Math.max(0, Math.min(results.length - 1, selected + delta))];
        if (item)
            selectedKey = Pass.key(item);
    }

    function typeIcon(type: string): string {
        return {
            login: Icons.key,
            note: Icons.noteText,
            alias: Icons.at,
            credit_card: Icons.creditCard,
            identity: Icons.identityCard,
            ssh_key: Icons.keyChain,
            wifi: Icons.wifi
        }[type] ?? Icons.shape;
    }

    function typeName(type: string): string {
        return {
            login: "Login",
            note: "Note",
            alias: "Alias",
            credit_card: "Credit card",
            identity: "Identity",
            ssh_key: "SSH key",
            wifi: "WiFi network"
        }[type] ?? "Item";
    }

    function fieldName(field: string): string {
        return {
            password: "password",
            number: "card number",
            private_key: "private key",
            note: "note",
            totp: "one-time code"
        }[field] ?? field;
    }

    function openItem(item: var) {
        if (!item)
            return;
        selectedKey = Pass.key(item);
        openedItem = item;
        actionIndex = 0;
        Pass.loadDetails(item);
    }

    function closeItem() {
        openedItem = null;
    }

    function runAction(action: var) {
        if (action.id === "user")
            copyUser();
        else if (action.id === "primary")
            copyPrimary();
        else if (action.id === "totp")
            copyTotp();
        else if (action.id === "url")
            openUrl();
        else if (action.id.startsWith("apiKey:"))
            Pass.copySecret(target, `extra:${action.id.slice(7)}`, action.what);
    }

    function copyPrimary() {
        const field = primaryFieldOf(target);
        if (field !== "")
            Pass.copySecret(target, field, fieldName(field));
    }

    function copyUser() {
        const user = userOf(target);
        if (user !== "")
            Pass.copyText(user, detailsOf(target).username !== "" ? "username" : "email");
    }

    // Tried before the details say whether there is one; pass-cli's error then says there isn't.
    function copyTotp() {
        if (target && (detailsOf(target)?.hasTotp ?? target.type === "login"))
            Pass.copySecret(target, "totp", fieldName("totp"));
    }

    function openUrl() {
        const url = urlOf(target);
        if (url === "")
            return;
        Qt.openUrlExternally(/^[a-z][a-z0-9+.-]*:/i.test(url) ? url : `https://${url}`);
        close();
    }

    function showNotice(text: string, isError: bool) {
        notice = text;
        noticeIsError = isError;
        noticeTimer.restart();
    }

    function handleKey(event: var) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const shift = event.modifiers & Qt.ShiftModifier;
        const alt = event.modifiers & Qt.AltModifier;
        const enter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
        if (event.key === Qt.Key_Escape) {
            // Back to the results first, like 1Password; Escape there closes.
            if (openedItem)
                closeItem();
            else
                close();
        } else if (!Pass.signedIn) {
            return;
        } else if (ctrl && shift && event.key === Qt.Key_C) {
            copyPrimary();
        } else if (ctrl && alt && event.key === Qt.Key_C) {
            copyTotp();
        } else if (ctrl && event.key === Qt.Key_C) {
            copyUser();
        } else if (alt && enter) {
            openUrl();
        } else if (openedItem) {
            if (event.key === Qt.Key_Up)
                actionIndex = Math.max(0, actionIndex - 1);
            else if (event.key === Qt.Key_Down)
                actionIndex = Math.min(actions.length - 1, actionIndex + 1);
            else if (enter && actions[actionIndex])
                runAction(actions[actionIndex]);
            else
                return;
        } else if (event.key === Qt.Key_Up) {
            move(-1);
        } else if (event.key === Qt.Key_Down) {
            move(1);
        } else if (event.key === Qt.Key_PageUp) {
            move(-visibleRows);
        } else if (event.key === Qt.Key_PageDown) {
            move(visibleRows);
        } else if (enter) {
            openItem(current);
        } else {
            return;
        }
        event.accepted = true;
    }

    // Typing again goes back to the results, as in 1Password.
    onQueryChanged: {
        selectedKey = "";
        openedItem = null;
    }
    onCurrentChanged: detailsDelay.restart()
    // The menu grows when the item's details arrive; keep the highlight on a row that exists.
    onActionsChanged: actionIndex = Math.min(actionIndex, Math.max(0, actions.length - 1))

    IpcHandler {
        target: "pass"

        function toggle(): void {
            root.toggle();
        }
    }

    Connections {
        target: Pass

        function onCopied(what: string, clearAfter: int) {
            root.showNotice(clearAfter > 0 ? `Copied ${what} — clears in ${clearAfter}s` : `Copied ${what}`, false);
        }

        function onFailed(message: string) {
            root.showNotice(message, true);
        }

        // The browser needs the keyboard; the window comes back once signed in.
        function onSignInPageReady(url: string) {
            Qt.openUrlExternally(url);
            root.close();
        }

        function onSignedInNow() {
            if (!root.open)
                root.show();
        }
    }

    // Arrowing through the list shouldn't start a pass-cli call per row passed.
    Timer {
        id: detailsDelay
        interval: 150
        onTriggered: Pass.loadDetails(root.current)
    }

    Timer {
        id: noticeTimer
        interval: 5000
        onTriggered: root.notice = ""
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: Quickshell.screens.find(screen => screen.name === root.screenName) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "pass-quick-access"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Keys reach the search field first, and the scope itself while there is none.
            FocusScope {
                id: content

                anchors.fill: parent
                focus: true

                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => root.handleKey(event)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    id: card

                    x: Math.round((parent.width - width) / 2)
                    y: Math.round(parent.height * 0.2)
                    width: 560
                    height: body.implicitHeight + 24
                    radius: 12
                    color: Theme.mantle
                    border.color: Theme.surface0
                    border.width: 1
                    opacity: 0
                    transform: Translate {
                        id: slide
                        y: -8

                        Behavior on y {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "black"
                        shadowOpacity: 0.35
                        shadowBlur: 1
                        shadowVerticalOffset: 8
                    }

                    Component.onCompleted: {
                        opacity = 1;
                        slide.y = 0;
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Clicks inside the card don't count as outside.
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: body

                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Signed in: search, results, the selection's details.
                        Rectangle {
                            Layout.fillWidth: true
                            visible: Pass.signedIn
                            implicitHeight: 40
                            radius: 8
                            color: Theme.base

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Icon {
                                    text: Icons.search
                                    color: Theme.overlay0
                                    font.pixelSize: 16
                                }

                                TextInput {
                                    id: input

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    selectionColor: Theme.surface2
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    clip: true
                                    focus: true
                                    onVisibleChanged: {
                                        if (visible)
                                            forceActiveFocus();
                                    }
                                    text: root.query
                                    onTextEdited: root.query = text
                                    Keys.onPressed: event => root.handleKey(event)

                                    BarText {
                                        anchors.fill: parent
                                        visible: input.text === ""
                                        text: "Search Proton Pass"
                                        color: Theme.overlay0
                                        font.pixelSize: 13
                                    }
                                }

                                BarText {
                                    visible: Pass.loading
                                    text: "Syncing…"
                                    color: Theme.subtext0
                                    font.pixelSize: 11
                                }
                            }
                        }

                        ListView {
                            id: list

                            Layout.fillWidth: true
                            implicitHeight: Math.min(count, root.visibleRows) * root.rowHeight
                            visible: Pass.signedIn && count > 0 && root.openedItem === null
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.results
                            currentIndex: root.selected
                            highlightMoveDuration: 0
                            ScrollBar.vertical: ListScrollBar {}

                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                            delegate: Rectangle {
                                id: row

                                required property var modelData
                                required property int index

                                readonly property bool isCurrent: index === root.selected

                                // Clear of the scrollbar when the list scrolls.
                                width: ListView.view.width - (list.contentHeight > list.height ? 10 : 0)
                                height: root.rowHeight
                                radius: 8
                                color: isCurrent ? Theme.surface0 : rowArea.containsMouse ? Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.5) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Icon {
                                        Layout.preferredWidth: 18
                                        text: root.typeIcon(row.modelData.type)
                                        color: row.isCurrent ? Theme.blue : Theme.overlay0
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        BarText {
                                            Layout.fillWidth: true
                                            text: row.modelData.title
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        // The username once its details have been loaded, as 1Password shows it.
                                        BarText {
                                            Layout.fillWidth: true
                                            text: root.userOf(row.modelData) || root.typeName(row.modelData.type)
                                            color: Theme.subtext0
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    BarText {
                                        Layout.maximumWidth: 160
                                        text: row.modelData.vault
                                        color: Theme.subtext0
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: rowArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.openItem(row.modelData)
                                }
                            }
                        }

                        Message {
                            visible: Pass.signedIn && list.count === 0 && root.openedItem === null
                            title: {
                                if (root.query !== "" && Pass.loaded)
                                    return `No items match “${root.query}”`;
                                if (Pass.error !== "")
                                    return "Couldn't load your items";
                                return Pass.loaded ? "Your vaults are empty" : "Loading your items…";
                            }
                            detail: Pass.loaded ? "" : Pass.error
                            detailIsError: true
                            actionText: Pass.error !== "" && !Pass.loading ? "Try again" : ""
                            onAction: Pass.refresh()
                        }

                        // The open item: what it is, then its actions. Escape or the cross goes back.
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.topMargin: 4
                            visible: Pass.signedIn && root.openedItem !== null
                            spacing: 12

                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: 8
                                color: Theme.surface0

                                Icon {
                                    anchors.centerIn: parent
                                    text: root.typeIcon(root.openedItem?.type ?? "")
                                    color: Theme.blue
                                    font.pixelSize: 20
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                BarText {
                                    Layout.fillWidth: true
                                    text: root.openedItem?.title ?? ""
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                BarText {
                                    Layout.fillWidth: true
                                    text: {
                                        const item = root.openedItem;
                                        if (!item)
                                            return "";
                                        if (!root.detailsOf(item))
                                            return "Loading…";
                                        const parts = [root.userOf(item), root.urlOf(item)].filter(part => part !== "");
                                        return parts.length > 0 ? parts.join(" - ") : root.typeName(item.type);
                                    }
                                    color: Theme.subtext0
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 6
                                color: backArea.containsMouse ? Theme.surface0 : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    text: Icons.close
                                    color: Theme.overlay0
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: backArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.closeItem()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            visible: Pass.signedIn && root.openedItem !== null
                            spacing: 2

                            Repeater {
                                model: root.actions

                                ActionRow {
                                    required property var modelData
                                    required property int index

                                    Layout.topMargin: modelData.gap ? 8 : 0
                                    icon: modelData.icon
                                    label: modelData.label
                                    detail: modelData.detail ?? ""
                                    shortcut: modelData.shortcut
                                    highlighted: index === root.actionIndex
                                    onHovered: root.actionIndex = index
                                    onClicked: root.runAction(modelData)
                                }
                            }
                        }

                        // Signed out, signing in, or not known yet.
                        Message {
                            visible: !Pass.signedIn
                            icon: Icons.shieldLockOutline
                            title: {
                                if (Pass.signingIn)
                                    return "Waiting for you to sign in";
                                if (!Pass.known)
                                    return Pass.error !== "" ? "Couldn't reach Proton Pass" : "Checking Proton Pass…";
                                return "Sign in to Proton Pass";
                            }
                            detail: {
                                if (Pass.signingIn)
                                    return "Finish signing in in your browser; this window comes back when you're done.";
                                if (Pass.error !== "")
                                    return Pass.error;
                                return Pass.known ? "The sign-in page opens in your browser." : "";
                            }
                            detailIsError: Pass.error !== "" && !Pass.signingIn
                            actionText: {
                                if (Pass.signingIn)
                                    return "Open sign-in page";
                                if (!Pass.known)
                                    return Pass.error !== "" && !Pass.loading ? "Try again" : "";
                                return "Sign in";
                            }
                            secondaryText: Pass.signingIn ? "Cancel" : ""
                            onAction: {
                                if (Pass.signingIn)
                                    Qt.openUrlExternally(Pass.loginUrl);
                                else if (!Pass.known)
                                    Pass.refresh();
                                else
                                    Pass.signIn();
                            }
                            onSecondary: Pass.cancelSignIn()
                        }

                        // The last copy's confirmation; otherwise where the open item lives, or the
                        // keys and the account in the list.
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.topMargin: 4
                            visible: Pass.signedIn
                            spacing: 6

                            Icon {
                                visible: root.notice !== ""
                                text: root.noticeIsError ? Icons.close : Icons.check
                                color: root.noticeIsError ? Theme.red : Theme.green
                                font.pixelSize: 14
                            }

                            BarText {
                                Layout.fillWidth: true
                                // A failed refresh over cached items; without any, the message above says it.
                                readonly property string refreshError: Pass.loaded ? Pass.error : ""

                                text: {
                                    if (root.notice !== "")
                                        return root.notice;
                                    if (refreshError !== "")
                                        return refreshError;
                                    if (root.openedItem)
                                        return `Located in ${root.openedItem.vault}`;
                                    return list.count > 0 ? "Enter to open  ·  Ctrl+C username  ·  Ctrl+Shift+C password  ·  Ctrl+Alt+C code" : "";
                                }
                                color: {
                                    if (root.notice !== "")
                                        return root.noticeIsError ? Theme.red : Theme.text;
                                    return refreshError !== "" ? Theme.red : Theme.subtext0;
                                }
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            BarText {
                                text: Pass.account
                                color: Theme.subtext0
                                font.pixelSize: 11
                            }

                            BarText {
                                visible: root.openedItem === null
                                text: "Sign out"
                                color: signOutArea.containsMouse ? Theme.text : Theme.subtext0
                                font.pixelSize: 11

                                MouseArea {
                                    id: signOutArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Pass.signOut()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // One entry of the open item's menu: icon, label (and what it opens), and its key. Highlighted
    // by the keyboard or the pointer, like 1Password's menu.
    component ActionRow: Rectangle {
        id: action

        property string icon
        property string label
        property string detail
        property string shortcut
        property bool highlighted: false

        signal clicked
        signal hovered

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 6
        color: highlighted ? Theme.surface0 : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                Layout.preferredWidth: 18
                text: action.icon
                color: action.highlighted ? Theme.blue : Theme.overlay0
                font.pixelSize: 14
            }

            BarText {
                text: action.label
                font.pixelSize: 12
            }

            BarText {
                Layout.fillWidth: true
                text: action.detail
                color: Theme.subtext0
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            BarText {
                text: action.shortcut
                color: action.highlighted ? Theme.subtext1 : Theme.overlay0
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: actionArea

            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (containsMouse)
                    action.hovered();
            }
            onClicked: action.clicked()
        }
    }

    // A centred state: optional icon, title, detail and up to two buttons.
    component Message: ColumnLayout {
        id: message

        property string icon
        property string title
        property string detail
        property bool detailIsError: false
        property string actionText
        property string secondaryText

        signal action
        signal secondary

        Layout.fillWidth: true
        Layout.topMargin: icon !== "" ? 20 : 12
        Layout.bottomMargin: icon !== "" ? 16 : 12
        spacing: 6

        Icon {
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            visible: message.icon !== ""
            text: message.icon
            color: Theme.blue
            font.pixelSize: 32
        }

        BarText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: message.title
            font.pixelSize: 13
            font.bold: message.icon !== ""
            color: message.icon !== "" ? Theme.text : Theme.subtext0
        }

        BarText {
            Layout.fillWidth: true
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            visible: message.detail !== ""
            text: message.detail
            color: message.detailIsError ? Theme.red : Theme.subtext0
            font.pixelSize: 11
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            visible: message.actionText !== ""
            spacing: 8

            MessageButton {
                text: message.actionText
                primary: true
                onClicked: message.action()
            }

            MessageButton {
                visible: message.secondaryText !== ""
                text: message.secondaryText
                onClicked: message.secondary()
            }
        }
    }

    component MessageButton: Rectangle {
        id: button

        property string text
        property bool primary: false

        signal clicked

        implicitWidth: buttonLabel.implicitWidth + 28
        implicitHeight: 30
        radius: 6
        color: primary ? (buttonArea.containsMouse ? Theme.lavender : Theme.blue) : buttonArea.containsMouse ? Theme.surface1 : Theme.surface0

        BarText {
            id: buttonLabel

            anchors.centerIn: parent
            text: button.text
            color: button.primary ? Theme.crust : Theme.text
            font.pixelSize: 12
            font.bold: button.primary
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
