import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common

// One section of the control panel (ControlPanel): its 13px title, or a back row in a sub-view,
// over a body that scrolls inside the panel's fixed height, so a long list never grows the plate.
// Children go into the body's column.
ColumnLayout {
    id: root

    property string title
    // 11px text2 beside the title, on the right (when a reading was taken).
    property string detail: ""
    property bool back: false
    default property alias body: column.data

    signal backClicked

    spacing: 0

    // The same height as the back row, so the body starts at one place in every view.
    RowLayout {
        visible: !root.back
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.bottomMargin: 4
        Layout.preferredHeight: 32
        spacing: 8

        BarText {
            text: root.title
            font.pixelSize: 13
            font.bold: true
        }

        BarText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: root.detail
            color: Theme.text2
            font.pixelSize: 11
            elide: Text.ElideLeft
        }
    }

    BackButton {
        visible: root.back
        title: root.title
        onClicked: root.backClicked()
    }

    Flickable {
        id: flick

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ListScrollBar {}

        ColumnLayout {
            id: column
            width: flick.width - (flick.ScrollBar.vertical.visible ? 10 : 0)
            spacing: 4
        }
    }
}
