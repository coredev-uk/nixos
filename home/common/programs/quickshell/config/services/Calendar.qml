pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// iCloud events and Sonarr/Radarr releases via the quickshell-calendar helper
// (scripts/calendar-events.py). The month the popup shows and the ones either side stay loaded:
// fetched at startup, again when the popup moves past them, and refreshed once they're older
// than maxAge, so changing month never waits. Secrets come from Proton Pass through the session
// pass-cli keeps in the keyring, so fetching in the background never prompts.
Singleton {
    id: root

    readonly property int maxAge: 15 * 60 * 1000

    // The month the popup shows (0-11, as in Date).
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    // "yyyy-MM-dd" -> [{ title, detail, calendar, source, color, done, allDay, time, start, end }],
    // in display order, for every day loaded so far.
    property var days: ({})
    // [{ source, message }] of the last fetch.
    property var errors: []
    // Whether calendars.json exists; known once a fetch finished.
    property bool configured: false
    property bool loaded: false
    readonly property bool loading: proc.running
    // "yyyy-M" -> when that month's grid was last fetched without errors.
    property var fetched: ({})

    readonly property var sourceNames: ({
            icloud: "iCloud",
            sonarr: "Sonarr",
            radarr: "Radarr",
            config: "calendars.json",
            calendar: "Calendar"
        })

    function dayKey(day: date): string {
        return Qt.formatDate(day, "yyyy-MM-dd");
    }

    // Local midnight of an all-day "yyyy-MM-dd" (Date would parse it as UTC).
    function localDay(text: string): date {
        const [y, m, d] = text.split("-").map(Number);
        return new Date(y, m - 1, d);
    }

    function addDays(day: date, count: int): date {
        return new Date(day.getFullYear(), day.getMonth(), day.getDate() + count);
    }

    // Months out of range (-1, 12) roll over into the neighbouring years, as with Date.
    function monthKey(y: int, m: int): string {
        const first = new Date(y, m, 1);
        return `${first.getFullYear()}-${first.getMonth()}`;
    }

    // First day of the six-week grid that shows the month, leading days included.
    function gridStart(y: int, m: int): date {
        const first = new Date(y, m, 1);
        return addDays(first, -((first.getDay() - Qt.locale().firstDayOfWeek + 7) % 7));
    }

    function show(y: int, m: int) {
        year = y;
        month = m;
        ensure();
    }

    // Fetches the shown month and its neighbours in one go when any of them is missing or stale.
    function ensure() {
        const months = [-1, 0, 1].map(delta => monthKey(year, month + delta));
        const now = Date.now();
        if (months.every(key => fetched[key] !== undefined && now - fetched[key] < maxAge))
            return;
        if (proc.running) {
            // Checked again once the running fetch is done, for whatever is shown by then.
            proc.again = true;
            return;
        }
        proc.months = months;
        proc.first = gridStart(year, month - 1);
        proc.last = addDays(gridStart(year, month + 1), 42);
        proc.command = ["quickshell-calendar", dayKey(proc.first), dayKey(proc.last)];
        proc.running = true;
    }

    // Replaces the days in first..last (end exclusive) with the result's events.
    function apply(first: date, last: date, result: var) {
        const firstKey = dayKey(first);
        const lastKey = dayKey(last);
        const grouped = {};
        for (const key in days) {
            if (key < firstKey || key >= lastKey)
                grouped[key] = days[key];
        }
        const touched = [];
        for (const event of result.events) {
            const start = event.allDay ? localDay(event.start) : new Date(event.start);
            const end = event.allDay ? localDay(event.end) : new Date(event.end);
            if (start < first && end <= first)
                continue;
            const color = event.color || (event.source === "sonarr" ? Theme.series1 : event.source === "radarr" ? Theme.series3 : Theme.series4);
            // Every day the event touches; a timed one ending at midnight stays on its last day.
            let day = new Date(start.getFullYear(), start.getMonth(), start.getDate());
            if (day < first)
                day = first;
            do {
                if (day >= last)
                    break;
                const next = addDays(day, 1);
                let time = "All day";
                if (!event.allDay && start >= day)
                    time = Qt.formatTime(start, "HH:mm");
                else if (!event.allDay && end < next)
                    time = `Until ${Qt.formatTime(end, "HH:mm")}`;
                const key = dayKey(day);
                if (!touched.includes(key)) {
                    touched.push(key);
                    grouped[key] = [];
                }
                grouped[key].push({
                    title: event.title,
                    detail: event.detail,
                    calendar: event.calendar,
                    source: event.source,
                    color,
                    done: event.done,
                    allDay: time === "All day",
                    time,
                    start: start.getTime(),
                    end: end.getTime()
                });
                day = next;
            } while (day < end)
        }
        // All-day ones first, then by start.
        for (const key of touched)
            grouped[key].sort((a, b) => (b.allDay - a.allDay) || (a.start - b.start) || a.title.localeCompare(b.title));
        days = grouped;
        errors = result.errors;
        configured = result.configured;
        loaded = true;
    }

    Component.onCompleted: ensure()


    // Keeps the loaded months fresh while the bar runs; ensure() does nothing if they are.
    Timer {
        running: true
        repeat: true
        interval: root.maxAge
        onTriggered: root.ensure()
    }

    Process {
        id: proc

        property var months: []
        property date first
        property date last
        property bool again: false

        stdout: StdioCollector {
            id: out
        }
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            try {
                if (code !== 0)
                    throw new Error(err.text.trim().split("\n").pop() || `exited with ${code}`);
                const result = JSON.parse(out.text);
                root.apply(proc.first, proc.last, result);
                // With errors the next ensure() tries again, as it may well work then.
                if (result.errors.length === 0) {
                    const fetched = Object.assign({}, root.fetched);
                    for (const key of proc.months)
                        fetched[key] = Date.now();
                    root.fetched = fetched;
                }
            } catch (e) {
                // Whatever was loaded before stays shown.
                root.errors = [
                    {
                        source: "calendar",
                        message: e.message
                    }
                ];
                root.loaded = true;
            }
            if (again) {
                again = false;
                root.ensure();
            }
        }
    }
}
