import QtQuick
import Quickshell
import qs.common

// Popup attached to a bar item that opens away from the bar's screen edge.
// Content should fill the window inside `topInset`/`bottomInset`, which leave `gap` on the bar side.
PopupWindow {
    id: root

    required property Item anchorItem
    // Grab input so that clicking anywhere outside the popup closes it.
    property bool dismissible: false
    property int gap: 8
    readonly property int topInset: Theme.barAtTop ? gap : 0
    readonly property int bottomInset: Theme.barAtTop ? 0 : gap
    property double closedAt: 0

    signal opening

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        // Clicking the toggle button while open dismisses the grab first; don't reopen on that same click.
        if (Date.now() - closedAt < 250)
            return;
        opening();
        visible = true;
    }

    anchor.item: anchorItem
    anchor.edges: Theme.popupEdges
    anchor.gravity: Theme.popupEdges
    visible: false
    color: "transparent"
    grabFocus: dismissible

    onVisibleChanged: {
        if (!visible)
            closedAt = Date.now();
    }

    // Hyprland drops an xdg_popup that resizes while mapped until it is repositioned.
    onImplicitWidthChanged: {
        if (visible)
            Qt.callLater(root.anchor.updateAnchor);
    }
    onImplicitHeightChanged: {
        if (visible)
            Qt.callLater(root.anchor.updateAnchor);
    }

    // Shortcut needs an Item to find its window.
    Item {
        Shortcut {
            enabled: root.dismissible && root.visible
            sequence: "Escape"
            onActivated: root.visible = false
        }
    }
}
