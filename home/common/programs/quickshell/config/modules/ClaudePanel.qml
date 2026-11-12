import QtQuick
import qs.common
import qs.services
import qs.widgets

// The Claude meter's plate (ClaudeButton): the week (ClaudeUsageView) hung under the meter, for a
// look without opening the control panel, whose Claude section shows the same.
BarPopup {
    id: root

    implicitWidth: 300
    implicitHeight: frame.implicitHeight + gap
    dismissible: true

    onOpening: {
        ClaudeUsage.now = Date.now();
        ClaudeUsage.refresh(false);
    }

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: view.implicitHeight + 24

        ClaudeUsageView {
            id: view
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            onLinkOpened: root.visible = false
        }
    }
}
