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
        gridShift.from = delta > 0 ? 12 : -12;
        monthArrival.restart();
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
        radius: Theme.radiusRow
        color: area.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationState
                easing.type: Theme.easing
            }
        }

        Icon {
            id: label
            anchors.centerIn: parent
            color: area.containsMouse ? Theme.text2 : Theme.muted
            font.pixelSize: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    Plate {
        id: frame
        anchors.fill: parent
        anchors.topMargin: root.topInset
        anchors.bottomMargin: root.bottomInset
        implicitHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
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
                    color: Theme.text
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
                    color: Theme.text2
                    font.pixelSize: 11
                }
            }

            MonthGrid {
                id: grid
                Layout.fillWidth: true
                month: root.month
                year: root.year
                // The new month arrives from the side it lies on; a transform leaves the layout alone.
                transform: Translate {
                    id: shift
                }

                ParallelAnimation {
                    id: monthArrival

                    NumberAnimation {
                        id: gridShift
                        target: shift
                        property: "x"
                        to: 0
                        duration: Theme.durationMove
                        easing.type: Theme.easing
                    }

                    NumberAnimation {
                        target: grid
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Theme.durationMove
                        easing.type: Theme.easing
                    }
                }

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
                    radius: Theme.radiusRow
                    // Today is told by its gilt numeral, the selected day by a gilt ring.
                    color: area.containsMouse ? Theme.hover : "transparent"
                    // Always 1 wide so the ring can ease in; clear gilt draws nothing and fades
                    // without passing through black.
                    border.width: 1
                    border.color: selected ? Theme.gilt : Theme.tint(Theme.gilt, 0)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

                    // Raised the same on every day, dots or not, so the numbers sit on one line.
                    BarText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -3
                        text: day.model.day
                        // Days outside the month are muted, but never on the hover fill, where muted sinks.
                        color: day.model.today ? Theme.gilt : day.model.month === grid.month ? Theme.text : area.containsMouse ? Theme.text2 : Theme.muted
                        font.pixelSize: 12
                        font.bold: day.model.today
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
                                color: modelData
                                opacity: day.model.month === grid.month ? 1 : 0.5

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.durationState
                                        easing.type: Theme.easing
                                    }
                                }
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
                color: Theme.rule
            }

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    Layout.fillWidth: true
                    text: Qt.formatDate(root.selected, "dddd d MMMM")
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                BarText {
                    // Only before the first answer: later fetches refresh what's already shown.
                    visible: Calendar.loading && !Calendar.loaded
                    text: "Loading…"
                    color: Theme.text2
                    font.pixelSize: 11
                }
            }

            BarText {
                // A failed fetch leaves configured false; the errors below say why instead.
                visible: root.selectedEvents.length === 0 && Calendar.loaded && !Calendar.passSignedOut && Calendar.errors.length === 0
                Layout.fillWidth: true
                text: Calendar.configured ? "No events" : "Add calendars in ~/.config/quickshell/calendars.json"
                color: Theme.text2
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

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

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
                                color: Theme.text2
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
                                color: Theme.text2
                                font.pixelSize: 12
                            }
                        }

                        BarText {
                            Layout.fillWidth: true
                            Layout.leftMargin: 72
                            text: [event.modelData.detail, event.modelData.calendar].filter(part => part).join(" · ")
                            color: Theme.text2
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // One line for a signed-out Proton Pass instead of the same error per source, with the
            // way back in. The browser opens for the sign-in (PassQuickAccess handles the page).
            RowLayout {
                visible: Calendar.passSignedOut
                Layout.fillWidth: true
                spacing: 8

                BarText {
                    Layout.fillWidth: true
                    text: Pass.signingIn ? "Finish signing in to Proton Pass in your browser" : "Signed out of Proton Pass, so the calendars can't load"
                    color: Pass.signingIn ? Theme.text2 : Theme.caution
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    implicitWidth: signInLabel.implicitWidth + 20
                    implicitHeight: 24
                    radius: Theme.radiusRow
                    color: signInArea.containsMouse ? Theme.hover : "transparent"
                    border.color: Theme.rule
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationState
                            easing.type: Theme.easing
                        }
                    }

                    BarText {
                        id: signInLabel
                        anchors.centerIn: parent
                        text: Pass.signingIn ? "Cancel" : "Sign in"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: signInArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Pass.signingIn ? Pass.cancelSignIn() : Pass.signIn()
                    }
                }
            }

            Repeater {
                model: Calendar.errors

                BarText {
                    required property var modelData

                    Layout.fillWidth: true
                    text: `${Calendar.sourceNames[modelData.source] ?? modelData.source}: ${modelData.message}`
                    color: Theme.alert
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
