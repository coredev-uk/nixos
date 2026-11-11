pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// atlas's Nix state and the home-lab binary cache, from the quickshell-nix-status helper: one JSON
// object (schema in scripts/nix-status.sh) with every source optional, so offline the local
// fields still arrive and the cache's and the builds' are null. Read every 5 minutes in the background, again
// when the control panel opens, and every minute while the Nix view is showing (acquire()/release(),
// like Batteries); a read is never started on top of a running one.
Singleton {
    id: root

    // The helper's last object, null until the first read has finished.
    property var data: null
    // The helper printed nothing usable; the last good `data` stays.
    property bool failed: false
    // When `data`'s remote parts were read: fetchedAt only moves when the cache and GitHub's builds
    // were both read fresh, so "Checked HH:mm" tells how old a kept cache or build section is.
    property double fetchedAt: 0
    // GitHub and the cache answer slowly at times, and one timed-out read would otherwise turn the
    // view to "unreachable" until the next one. A miss keeps the last good section of each source
    // this long, and retries soon; past it, offline, the view goes to unreachable.
    readonly property int staleFor: 15 * 60 * 1000
    property int users: 0
    readonly property bool active: users > 0

    // The properties below are each derived from `data` alone; a view that combines several of
    // them reads `data` through stateOf() instead, since they update one after another.
    //
    // "loading" before the first read, "unreachable" while neither the cache nor GitHub's builds
    // answer (offline), then, first match wins: "failed" (main's latest host build failed, atlas's or
    // poseidon's, so a switch may build here), "update-failing" (a lock update has a failed check: one of
    // the nightly trials, one per flake input, or the landing pull request that merges the passing
    // ones), "update-pending" (updates are open and their checks still running, or landing),
    // "running" (a host build of main is in progress), "ok", or "never" (no finished host build
    // of main to go by, or GitHub didn't answer).
    readonly property string state: stateOf(data)
    readonly property bool updateAvailable: data?.upstream?.update_available ?? false
    readonly property bool rebootPending: data?.system?.reboot_pending ?? false
    // Something that keeps updates from landing has failed: main's build or an update's checks.
    readonly property bool lastFailed: ["failed", "update-failing"].includes(state)
    // Failed systemd units, system and user ([{ scope, name, description }]); empty when none or
    // when neither manager answered (`data.failed_units` null), so a missing read stays calm.
    readonly property var failedUnits: data?.failed_units ?? []
    // One line for the panel row.
    readonly property string summary: summaryOf(data)

    function stateOf(d: var): string {
        if (d === null || d === undefined)
            return failed ? "unreachable" : "loading";
        if (!(d.cache?.reachable ?? false) && !(d.build?.reachable ?? false))
            return "unreachable";
        if (d.build?.main?.success === false)
            return "failed";
        if (failingUpdates(d).length > 0)
            return "update-failing";
        if ((d.updates ?? []).length > 0)
            return "update-pending";
        if (d.build?.running ?? false)
            return "running";
        if (d.build?.main?.success === true)
            return "ok";
        return "never";
    }

    function failingChecks(update: var): var {
        return (update?.checks ?? []).filter(c => c.state === "failure");
    }

    function pendingChecks(update: var): var {
        return (update?.checks ?? []).filter(c => c.state === "pending");
    }

    // The open lock updates with a failed check, longest-failing first.
    function failingUpdates(d: var): var {
        return (d?.updates ?? []).filter(u => failingChecks(u).length > 0).sort((a, b) => (updateFailingSince(a) ?? 0) - (updateFailingSince(b) ?? 0));
    }

    // When an update started failing: the earliest failed check on its current commit.
    function updateFailingSince(update: var): var {
        const times = failingChecks(update).map(c => c.since).filter(t => t !== null && t !== undefined);
        return times.length === 0 ? null : Math.min(...times);
    }

    // The open landing pull request (the passing trials merged together), or null.
    function landingOf(d: var): var {
        return (d?.updates ?? []).find(u => u.kind === "landing") ?? null;
    }

    // The open trials (one draft pull request per flake input).
    function trialsOf(d: var): var {
        return (d?.updates ?? []).filter(u => u.kind === "trial");
    }

    // "unstable", "the lock update" for the landing pull request.
    function nameOf(update: var): string {
        return update.kind === "landing" ? "the lock update" : update.input;
    }

    // "unstable and sona", "3 updates" past two.
    function inputs(updates: var): string {
        if (updates.length > 2)
            return `${updates.length} updates`;
        return updates.map(nameOf).join(" and ");
    }

    // "atlas and poseidon", "3 checks" past two.
    function names(checks: var): string {
        if (checks.length > 2)
            return `${checks.length} checks`;
        return checks.map(c => c.name).join(" and ");
    }

    function summaryOf(d: var): string {
        const build = d?.build;
        const parts = [];
        switch (stateOf(d)) {
        case "loading":
            return "Checking…";
        case "unreachable":
            parts.push("Cache and GitHub unreachable");
            break;
        case "failed":
            parts.push(`main failing${build.main.failing_since ? ` for ${span(now / 1000 - build.main.failing_since)}` : ""}`);
            break;
        case "update-failing":
            {
                const failing = failingUpdates(d);
                const since = updateFailingSince(failing[0]);
                const what = failing.length > 1 ? inputs(failing) : failing[0].kind === "landing" ? "Lock update" : `${failing[0].input} update`;
                parts.push(`${what} failing${since === null ? "" : ` for ${span(now / 1000 - since)}`}`);
                break;
            }
        case "update-pending":
            {
                const landing = landingOf(d);
                const trials = trialsOf(d);
                const testing = trials.filter(t => pendingChecks(t).length > 0 || t.checks === null);
                if (landing !== null)
                    parts.push(landing.inputs.length === 1 ? `Landing ${landing.inputs[0]}` : `Landing ${landing.inputs.length} updates`);
                else if (testing.length > 0)
                    parts.push(testing.length === 1 ? `Testing ${testing[0].input}` : `Testing ${testing.length} updates`);
                else
                    parts.push(trials.length === 1 ? `${trials[0].input} update passed` : `${trials.length} updates passed`);
                break;
            }
        case "running":
            parts.push("Build running");
            break;
        case "ok":
            parts.push(`Built ${ago(build.main.finished)}`);
            break;
        case "never":
            parts.push("No build result");
            break;
        }
        if (d.upstream?.update_available)
            parts.push("switch pending");
        if (d.system?.reboot_pending)
            parts.push("reboot pending");
        const failedCount = d.failed_units?.length ?? 0;
        if (failedCount > 0)
            parts.push(failedCount === 1 ? "1 unit failed" : `${failedCount} units failed`);
        return parts.join(" · ");
    }

    // Times are relative to when the data was read, so a shown value never ticks under the pointer.
    readonly property double now: fetchedAt > 0 ? fetchedAt : Date.now()

    // "3 h ago" for an epoch in seconds.
    function ago(epoch: var): string {
        if (epoch === null || epoch === undefined)
            return "";
        const seconds = Math.max(0, now / 1000 - epoch);
        return seconds < 60 ? "just now" : `${span(seconds)} ago`;
    }

    // "5 min", "3 h", "12 d" for a number of seconds.
    function span(seconds: real): string {
        if (seconds < 60)
            return `${Math.round(seconds)} s`;
        const minutes = Math.round(seconds / 60);
        if (minutes < 60)
            return `${minutes} min`;
        const hours = Math.round(seconds / 3600);
        if (hours < 48)
            return `${hours} h`;
        return `${Math.round(seconds / 86400)} d`;
    }

    function bytes(n: var): string {
        if (n === null || n === undefined)
            return "";
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = n;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return unit === 0 ? `${Math.round(value)} B` : `${value.toFixed(value >= 100 ? 0 : 1)} ${units[unit]}`;
    }

    function acquire() {
        users++;
    }

    function release() {
        users = Math.max(0, users - 1);
    }

    // `soon`: skip when the last read is that recent (ms), for the panel opening on every screen.
    function refresh(soon = 0) {
        if (proc.running || (soon > 0 && Date.now() - fetchedAt < soon))
            return;
        proc.running = true;
    }

    onActiveChanged: {
        if (active)
            refresh(20000);
    }
    Component.onCompleted: refresh()

    Process {
        id: proc
        command: ["quickshell-nix-status"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(out.text);
                } catch (e) {
                    root.failed = true;
                    return;
                }
                root.failed = false;
                root.accept(parsed);
            }
        }
    }

    // `next`'s local fields always win; a remote section that came back unreachable is replaced by
    // the previous one while that is recent (see staleFor). The cache, GitHub's builds, upstream and the
    // updates each stand alone.
    function accept(next: var) {
        const prev = root.data;
        const recent = prev !== null && Date.now() - root.fetchedAt < root.staleFor;
        const merged = Object.assign({}, next);
        let missed = false;
        let kept = false;
        if (!(next.cache?.reachable) && recent && prev.cache?.reachable) {
            merged.cache = prev.cache;
            kept = true;
        }
        if (!(next.build?.reachable) && recent && prev.build?.reachable) {
            merged.build = prev.build;
            kept = true;
        }
        if (kept) {
            missed = true;
        } else {
            root.fetchedAt = next.fetched_at * 1000;
        }
        if (!(next.upstream?.reachable) && recent && prev.upstream?.reachable) {
            merged.upstream = prev.upstream;
            missed = true;
        }
        if ((next.updates === null || next.updates === undefined) && recent && prev.updates) {
            merged.updates = prev.updates;
            missed = true;
        }
        if (next.system) {
            const keep = {};
            for (const key of ["cached", "matches_main"]) {
                if (next.system[key] === null && recent && prev.system?.[key] !== null && prev.system?.[key] !== undefined)
                    keep[key] = prev.system[key];
            }
            if (Object.keys(keep).length > 0) {
                merged.system = Object.assign({}, next.system, keep);
                missed = true;
            }
        }
        root.data = merged;
        if (missed)
            retry.restart();
    }

    Timer {
        id: retry
        interval: 30000
        onTriggered: root.refresh()
    }

    Timer {
        interval: root.active ? 60000 : 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
