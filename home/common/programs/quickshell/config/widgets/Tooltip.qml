import QtQuick
import qs.common

// Hover tooltip rendered as a popup, since bar windows are too short to host one.
BarPopup {
    id: root

    property string text: ""
    property bool active: false

    gap: 6
    // Long tooltips (e.g. several apps using the mic) wrap past 360px.
    implicitWidth: Math.min(Math.ceil(metrics.advanceWidth), 360) + 16
    implicitHeight: label.implicitHeight + 10 + gap

    onActiveChanged: {
        if (active) {
            delay.restart();
        } else {
            delay.stop();
            visible = false;
        }
    }

    TextMetrics {
        id: metrics
        font: label.font
        text: root.text
    }

    Timer {
        id: delay
        interval: 400
        onTriggered: root.visible = root.text !== ""
    }

    Plate {
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        radius: Theme.radiusRow

        BarText {
            id: label
            anchors.centerIn: parent
            width: Math.min(Math.ceil(metrics.advanceWidth), 360)
            wrapMode: Text.Wrap
            text: root.text
            font.pixelSize: 12
        }
    }
}
