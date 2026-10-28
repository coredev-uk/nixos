import QtQuick
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Bottom-right, from the user session: a day view of what's left of today in the calendar
// (services/Calendar) on a dark card, its foot level with the time's baseline; and in the date
// line under it, what's playing. The power buttons (LockPower) take the music's place while the
// password is up.
Item {
    id: root

    required property AuthContext context
    property real s: 1
    property real margin: 80
    property real lineHeight: 56

    readonly property bool engaged: context.active && !context.unlocking
    readonly property int maxEvents: 4
    readonly property real now: clock.date.getTime()
    // Today's events that aren't over, all-day ones first as Calendar sorts them; done
    // reminders are left out.
    readonly property var events: (Calendar.days[Calendar.dayKey(clock.date)] ?? []).filter(event => !event.done && (event.allDay || event.end > now))
    readonly property var shownEvents: events.slice(0, maxEvents)
    // The timed event on now or next; it says how long until it starts.
    readonly property var nextEvent: events.find(event => !event.allDay) ?? null

    // "15:30 – 16:15", or Calendar's own label for all-day and carried-over events.
    function span(event: var): string {
        if (event.allDay || event.time.startsWith("Until"))
            return event.time;
        return `${event.time} – ${Qt.formatTime(new Date(event.end), "HH:mm")}`;
    }

    function countdown(event: var): string {
        const minutes = Math.ceil((event.start - now) / 60000);
        if (minutes <= 0)
            return "Now";
        if (minutes < 60)
            return `In ${minutes} min`;
        const hours = Math.floor(minutes / 60);
        return minutes % 60 ? `In ${hours} h ${minutes % 60} min` : `In ${hours} h`;
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        id: card

        // Rows sit closer to the edge than the header so the next event's tint has room.
        readonly property real inset: Math.round(12 * root.s)
        readonly property real rowPadding: Math.round(16 * root.s)

        anchors.right: parent.right
        anchors.rightMargin: root.margin
        // The foot level with the time's baseline, 40 above the date line (LockClock).
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.margin + root.lineHeight + Math.round(40 * root.s)
        width: Math.round(500 * root.s)
        height: list.implicitHeight + Math.round(22 * root.s) + inset
        radius: Math.round(26 * root.s)
        color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.8)
        opacity: root.events.length > 0 ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: card.inset
            anchors.rightMargin: card.inset
            anchors.topMargin: Math.round(22 * root.s)
            spacing: Math.round(4 * root.s)

            Item {
                width: parent.width
                height: heading.implicitHeight + Math.round(10 * root.s)

                Text {
                    id: heading

                    x: card.rowPadding
                    text: "Today"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(19 * root.s)
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: card.rowPadding
                    anchors.baseline: heading.baseline
                    text: root.events.length === 1 ? "1 event" : `${root.events.length} events`
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(16 * root.s)
                }
            }

            Repeater {
                model: root.shownEvents

                // One event: the calendar's colour as a bar down its left, as in a day view; the
                // next one tinted, with how long until it starts.
                Rectangle {
                    id: event

                    required property var modelData
                    // By value: the model hands each row its own copy of the event.
                    readonly property bool next: root.nextEvent !== null && !modelData.allDay && modelData.start === root.nextEvent.start && modelData.title === root.nextEvent.title

                    width: list.width
                    height: details.implicitHeight + 2 * Math.round(12 * root.s)
                    radius: Math.round(14 * root.s)
                    color: next ? Qt.rgba(1, 1, 1, 0.07) : "transparent"

                    Rectangle {
                        x: card.rowPadding
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(4 * root.s)
                        height: details.implicitHeight
                        radius: width / 2
                        color: event.modelData.color
                    }

                    Column {
                        id: details

                        anchors.left: parent.left
                        anchors.leftMargin: card.rowPadding + Math.round(20 * root.s)
                        anchors.right: parent.right
                        anchors.rightMargin: card.rowPadding
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(4 * root.s)

                        Item {
                            width: parent.width
                            height: title.implicitHeight

                            Text {
                                id: title

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.rightMargin: event.next ? countdown.implicitWidth + Math.round(16 * root.s) : 0
                                elide: Text.ElideRight
                                text: event.modelData.title
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(22 * root.s)
                                font.weight: Font.Medium
                            }

                            Text {
                                id: countdown

                                anchors.right: parent.right
                                anchors.baseline: title.baseline
                                visible: event.next
                                text: event.next ? root.countdown(event.modelData) : ""
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(17 * root.s)
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: [root.span(event.modelData), event.modelData.calendar].filter(part => part).join("  ·  ")
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(17 * root.s)
                        }
                    }
                }
            }

            Text {
                visible: root.events.length > root.maxEvents
                leftPadding: card.rowPadding + Math.round(20 * root.s)
                topPadding: Math.round(4 * root.s)
                text: `${root.events.length - root.maxEvents} more today`
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(17 * root.s)
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: root.margin
        y: parent.height - root.margin - (root.lineHeight + height) / 2
        spacing: Math.round(12 * root.s)
        opacity: !root.engaged && Media.active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.music
            color: Theme.text
            font.pixelSize: Math.round(22 * root.s)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.round(560 * root.s))
            elide: Text.ElideRight
            text: [Media.player?.trackTitle, Media.player?.trackArtist].filter(part => part).join(" — ")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(19 * root.s)
            font.weight: Font.Medium
        }
    }
}
