import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

BarPopup {
    id: root

    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    // Local midnight of the day whose events are listed.
    property date selected: today()
    readonly property string selectedKey: Calendar.dayKey(selected)
    readonly property var selectedEvents: Calendar.days[selectedKey] ?? []

    function today(): date {
        const now = new Date();
        return new Date(now.getFullYear(), now.getMonth(), now.getDate());
    }

    onOpening: {
        selected = today();
        month = selected.getMonth();
        year = selected.getFullYear();
        Calendar.show(year, month);
    }

    // Today when it's in the new month, else the 1st.
    function shiftMonth(delta: int) {
        const date = new Date(year, month + delta, 1);
        month = date.getMonth();
        year = date.getFullYear();
        const now = today();
        selected = now.getMonth() === month && now.getFullYear() === year ? now : date;
        Calendar.show(year, month);
    }

    implicitWidth: 350
    implicitHeight: frame.implicitHeight + gap
    dismissible: true

    component NavButton: Rectangle {
        id: button

        property alias icon: label.text

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: 6
        color: area.containsMouse ? Theme.surface0 : "transparent"

        Icon {
            id: label
            anchors.centerIn: parent
            color: Theme.lavender
            font.pixelSize: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: content.implicitHeight + 32
        radius: 12
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                NavButton {
                    icon: Icons.chevronLeft
                    onClicked: root.shiftMonth(-1)
                }

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                    color: Theme.lavender
                    font.pixelSize: 13
                    font.bold: true
                }

                NavButton {
                    icon: Icons.chevronRight
                    onClicked: root.shiftMonth(1)
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: grid.locale
                delegate: BarText {
                    required property string shortName

                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.lavender
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            MonthGrid {
                id: grid
                Layout.fillWidth: true
                month: root.month
                year: root.year
                delegate: Rectangle {
                    id: day

                    required property var model
                    readonly property date local: new Date(model.year, model.month, model.day)
                    readonly property string key: Calendar.dayKey(local)
                    readonly property bool selected: key === root.selectedKey
                    // One dot per calendar colour, at most three.
                    readonly property var dots: {
                        const colors = [];
                        for (const event of Calendar.days[key] ?? []) {
                            const color = String(event.color).toLowerCase();
                            if (!colors.includes(color))
                                colors.push(color);
                        }
                        return colors.slice(0, 3);
                    }

                    implicitWidth: 40
                    implicitHeight: 32
                    radius: 6
                    color: model.today ? Theme.pink : selected || area.containsMouse ? Theme.surface0 : "transparent"
                    border.width: selected && !model.today ? 1 : 0
                    border.color: Theme.lavender

                    BarText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: day.dots.length > 0 ? -3 : 0
                        text: day.model.day
                        color: day.model.today ? Theme.base : day.model.month === grid.month ? Theme.text : Theme.surface2
                        font.pixelSize: 12
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        spacing: 2

                        Repeater {
                            model: day.dots

                            Rectangle {
                                required property string modelData

                                width: 4
                                height: 4
                                radius: 2
                                // Calendar colours would clash with today's highlight.
                                color: day.model.today ? Theme.base : modelData
                                opacity: day.model.month === grid.month ? 1 : 0.5
                            }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.selected = day.local
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Theme.surface0
            }

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    Layout.fillWidth: true
                    text: Qt.formatDate(root.selected, "dddd d MMMM")
                    color: Theme.lavender
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                BarText {
                    // Only before the first answer: later fetches refresh what's already shown.
                    visible: Calendar.loading && !Calendar.loaded
                    text: "Loading…"
                    color: Theme.subtext0
                    font.pixelSize: 11
                }
            }

            BarText {
                visible: root.selectedEvents.length === 0 && Calendar.loaded
                Layout.fillWidth: true
                text: Calendar.configured ? "No events" : "Add calendars in ~/.config/quickshell/calendars.json"
                color: Theme.subtext0
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            ListView {
                visible: count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 180)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ListScrollBar {}
                spacing: 6
                model: root.selectedEvents
                delegate: RowLayout {
                    id: event

                    required property var modelData

                    width: ListView.view.width - (ListView.view.ScrollBar.vertical.visible ? 10 : 0)
                    spacing: 8
                    // Releases already downloaded.
                    opacity: modelData.done ? 0.5 : 1

                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: 3
                        radius: 1.5
                        color: event.modelData.color
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            BarText {
                                Layout.preferredWidth: 64
                                text: event.modelData.time
                                color: Theme.subtext0
                                font.pixelSize: 11
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: event.modelData.title
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Icon {
                                visible: event.modelData.done
                                text: Icons.check
                                color: Theme.green
                                font.pixelSize: 12
                            }
                        }

                        BarText {
                            Layout.fillWidth: true
                            Layout.leftMargin: 72
                            text: [event.modelData.detail, event.modelData.calendar].filter(part => part).join(" · ")
                            color: Theme.subtext0
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Repeater {
                model: Calendar.errors

                BarText {
                    required property var modelData

                    Layout.fillWidth: true
                    text: `${Calendar.sourceNames[modelData.source] ?? modelData.source}: ${modelData.message}`
                    color: Theme.red
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
