pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude plan usage for the control panel's Claude section, from the quickshell-claude-usage
// helper (schema in scripts/claude-usage.sh): this week's limits and the week's readings of the
// weekly limit. Read every 5 minutes, so the chart has the whole week and the rail can report the
// limit, and again when the section shows; a read never starts on top of a running one. Signed in
// with omp's credential, which only omp refreshes: while it has expired the last reading stays,
// marked with its time.
Singleton {
    id: root

    readonly property double week: 7 * 24 * 3600 * 1000

    // The helper's last object, null until the first read has finished.
    property var data: null
    // A minute clock for the pace, the week's tick and "in 2 d 20 h".
    property double now: Date.now()

    // "ok", "expired" (omp's token; it refreshes the next time omp runs), "rejected", "limited"
    // (asked too often), "unreachable" (offline), "failed", "signed-out" (no Claude sign-in in
    // omp), or "loading" before the first read.
    readonly property string status: data?.status ?? "loading"
    readonly property double fetchedAt: (data?.fetched_at ?? 0) * 1000
    readonly property var limits: data?.usage?.limits ?? []
    readonly property var weekly: limits.find(l => l.kind === "weekly_all") ?? null
    readonly property bool available: weekly !== null && weekly.resets_at !== null
    // Model and session limits, beside the weekly one.
    readonly property var others: limits.filter(l => l.kind !== "weekly_all")
    readonly property var extra: data?.usage?.extra ?? null

    // The week the reading is for. Once its reset has passed, a reading not yet taken again is last
    // week's: the new week starts from nothing until the next read.
    readonly property double weekEnd: {
        if (!available)
            return 0;
        let end = weekly.resets_at * 1000;
        while (end <= now)
            end += week;
        return end;
    }
    readonly property double weekStart: weekEnd - week
    readonly property bool reset: available && weekEnd !== weekly.resets_at * 1000
    readonly property real percent: available && !reset ? weekly.percent : 0
    // How much of the week has gone, 0-1.
    readonly property real elapsed: available ? Math.min(Math.max((now - weekStart) / week, 0), 1) : 0
    readonly property bool full: percent >= 100 || (available && !reset && ["critical", "locked"].includes(weekly.severity))
    readonly property bool high: !full && (percent >= 90 || (available && !reset && weekly.severity === "warning"))
    // Where the week ends at the rate it has gone so far. Not before half a day has gone, when one
    // morning's work would read as the whole week's pace.
    readonly property bool paced: elapsed >= 0.05
    readonly property real projected: paced ? percent / elapsed : 0
    // When the limit is reached at that rate, or 0 when it lasts the week.
    readonly property double runsOutAt: {
        if (!paced || full || percent <= 0)
            return 0;
        const at = weekStart + (now - weekStart) * 100 / percent;
        return at < weekEnd ? at : 0;
    }
    // This week's readings, [ms, percent], oldest first, ending at the one shown (omp's readings
    // can be newer than the shell's own).
    readonly property var history: {
        if (!available || reset)
            return [];
        const points = (data?.history ?? []).map(p => [p[0] * 1000, p[1]]).filter(p => p[0] >= weekStart && p[0] < fetchedAt);
        points.push([fetchedAt, percent]);
        return points;
    }

    // The endpoint rate-limits, and omp reads it too: a read asked for within two minutes of the
    // last good one is skipped unless `force`.
    function refresh(force: bool) {
        if (proc.running || (!force && status === "ok" && Date.now() - fetchedAt < 2 * 60 * 1000))
            return;
        proc.running = true;
    }

    // "2 d 20 h", "5 h 10 min", "12 min".
    function span(ms: double): string {
        const minutes = Math.max(0, Math.round(ms / 60000));
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor(minutes % 1440 / 60);
        if (days > 0)
            return `${days} d ${hours} h`;
        if (hours > 0)
            return `${hours} h ${minutes % 60} min`;
        return `${minutes} min`;
    }

    // "Sun 18:00", or "18:00" for a time today.
    function when(ms: double): string {
        const date = new Date(ms);
        return date.toDateString() === new Date(now).toDateString() ? Qt.formatTime(date, "HH:mm") : Qt.formatDateTime(date, "ddd HH:mm");
    }

    Process {
        id: proc
        command: ["quickshell-claude-usage"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                try {
                    root.data = JSON.parse(out.text);
                } catch (e) {
                    // Nothing usable printed; the last reading stays.
                }
                root.now = Date.now();
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh(true)
    }

    Timer {
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }
}
