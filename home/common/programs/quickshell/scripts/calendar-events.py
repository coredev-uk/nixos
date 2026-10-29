# Events for the bar's calendar (config/services/Calendar.qml), from iCloud
# over CalDAV and the Sonarr/Radarr release calendars.
#
#   quickshell-calendar START END    (ISO dates, END exclusive)
#
# Sources come from $XDG_CONFIG_HOME/quickshell/calendars.json, kept out of
# git; every section is optional:
#
#   {
#     "icloud": {"username": "pass://Vault/iCloud/email",
#                "password": "pass://Vault/iCloud/password"},
#     "sonarr": {"url": "http://host:8989",
#                "apiKey": "pass://Vault/Sonarr/password"},
#     "radarr": {"url": "http://host:7878",
#                "apiKey": "pass://Vault/Radarr/password"}
#   }
#
# The iCloud password is an app-specific one (account.apple.com, Sign-In and
# Security). Any value starting with pass:// (vault/item/field, by name) is
# read from Proton Pass with pass-cli on each run, through the session it keeps
# in the keyring, so nothing prompts; anything else is used as is.
#
# Prints one JSON object, events unsorted:
#   {"configured": bool,
#    "events": [{"title", "detail", "start", "end", "allDay", "source",
#                "calendar", "color", "done"}],
#    "errors": [{"source", "message"}],
#    "passSignedOut": true}  (only when Proton Pass has no session)
# All-day events have date starts/ends (end exclusive); timed ones ISO
# datetimes, with an offset unless floating (local time). A failing source
# only adds an error; the others still report their events.

import fcntl
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone

import caldav
import requests
from caldav.elements import cdav, dav, ical
from caldav.lib.error import AuthorizationError

ICLOUD_URL = "https://caldav.icloud.com/"
TIMEOUT = 20
PASS_TIMEOUT = 30
RADARR_RELEASES = [
    ("inCinemas", "Cinema"),
    ("digitalRelease", "Digital"),
    ("physicalRelease", "Physical"),
]


class SourceError(Exception):
    pass


class PassSignedOut(SourceError):
    pass


def config_path():
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser(
        "~/.config")
    return os.path.join(base, "quickshell", "calendars.json")


def read_secret(ref):
    # As in pass.sh: without the dbus key store, pass-cli falls back to the
    # kernel keyring, is denied, and deletes the signed-in session. Callers
    # (the bar, the lock under hypridle) can start before the session
    # variables are in place, so don't rely on them.
    env = dict(os.environ, PROTON_PASS_LINUX_KEYRING="dbus",
               PROTON_PASS_NO_UPDATE_CHECK="1")
    try:
        proc = subprocess.run(
            ["pass-cli", "item", "view", ref],
            capture_output=True,
            text=True,
            timeout=PASS_TIMEOUT,
            env=env,
        )
    except FileNotFoundError:
        raise SourceError("Proton Pass CLI (pass-cli) not found")
    except subprocess.TimeoutExpired:
        raise SourceError(f"Timed out reading {ref} from Proton Pass")
    if proc.returncode != 0:
        if "requires an authenticated client" in proc.stderr:
            raise PassSignedOut("Proton Pass is signed out")
        # The cause is the last line: "    1: Could not find item with name X".
        reason = (proc.stderr.strip().splitlines() or ["failed"])[-1]
        reason = reason.strip().split(": ", 1)[-1]
        raise SourceError(f"Proton Pass: {reason}")
    # pass-cli ends the value with a newline.
    return proc.stdout.removesuffix("\n")


def pass_lock():
    """The shared side of quickshell-pass's lock (scripts/pass.sh): a pass-cli
    call during a pending web login deletes the half-made session, so secrets
    are only read while no login holds it. Released when the process exits."""
    runtime = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    lock = open(os.path.join(runtime, "quickshell-pass.lock"), "a")
    try:
        fcntl.flock(lock, fcntl.LOCK_SH | fcntl.LOCK_NB)
    except BlockingIOError:
        lock.close()
        raise SourceError("Finish signing in to Proton Pass first")
    return lock


def settings(section, keys):
    """The section's values for `keys`, pass:// references resolved."""
    if not isinstance(section, dict):
        raise SourceError("Expected an object in calendars.json")
    values = {}
    for key in keys:
        value = section.get(key)
        if not isinstance(value, str) or not value:
            raise SourceError(f"Missing \"{key}\" in calendars.json")
        values[key] = read_secret(value) if value.startswith(
            "pass://") else value
    return values


def iso(value):
    return value.isoformat()


def in_range(day, start, end):
    return start <= day < end


def arr_get(base, api_key, path, params):
    url = base.rstrip("/") + path
    try:
        response = requests.get(
            url,
            params=params,
            headers={"X-Api-Key": api_key},
            timeout=TIMEOUT,
        )
    except requests.Timeout:
        raise SourceError(f"Timed out reaching {base}")
    except requests.RequestException:
        raise SourceError(f"Couldn't reach {base}")
    if response.status_code == 401:
        raise SourceError("Unauthorized: check the API key")
    if not response.ok:
        raise SourceError(f"HTTP {response.status_code} from {base}")
    try:
        return response.json()
    except ValueError:
        raise SourceError(f"Unexpected response from {base}")


def sonarr_events(conf, start, end):
    episodes = arr_get(conf["url"], conf["apiKey"], "/api/v3/calendar", {
        "start": start.isoformat(),
        "end": end.isoformat(),
        "includeSeries": "true",
    })
    events = []
    for episode in episodes:
        series = episode.get("series") or {}
        title = "{} S{:02}E{:02}".format(
            series.get("title") or "Unknown series",
            episode.get("seasonNumber", 0),
            episode.get("episodeNumber", 0),
        )
        aired = episode.get("airDateUtc")
        if aired:
            begin = datetime.fromisoformat(aired)
            runtime = timedelta(minutes=series.get("runtime") or 0)
            begin_iso, end_iso = iso(begin), iso(begin + runtime)
            all_day = False
        elif episode.get("airDate"):
            day = date.fromisoformat(episode["airDate"])
            begin_iso = iso(day)
            end_iso, all_day = iso(day + timedelta(days=1)), True
        else:
            continue
        events.append({
            "title": title,
            "detail": episode.get("title") or "",
            "start": begin_iso,
            "end": end_iso,
            "allDay": all_day,
            "source": "sonarr",
            "calendar": "Sonarr",
            "color": "",
            "done": bool(episode.get("hasFile")),
        })
    return events, []


def radarr_events(conf, start, end):
    movies = arr_get(conf["url"], conf["apiKey"], "/api/v3/calendar", {
        "start": start.isoformat(),
        "end": end.isoformat(),
    })
    events = []
    for movie in movies:
        # The calendar lists a movie when any of its dates is in range.
        for field, label in RADARR_RELEASES:
            released = movie.get(field)
            if not released:
                continue
            day = date.fromisoformat(released[:10])
            if not in_range(day, start, end):
                continue
            events.append({
                "title": movie.get("title") or "Unknown movie",
                "detail": f"{label} release",
                "start": iso(day),
                "end": iso(day + timedelta(days=1)),
                "allDay": True,
                "source": "radarr",
                "calendar": "Radarr",
                "color": "",
                "done": bool(movie.get("hasFile")),
            })
    return events, []


def ical_color(value):
    # iCloud gives #RRGGBBAA, which Qt would read as #AARRGGBB.
    if len(value) == 9 and value.startswith("#"):
        return value[:7]
    return value


def ical_time(value):
    return iso(value), not isinstance(value, datetime)


def calendar_info(calendar):
    """Name, colour and whether it holds events, in one PROPFIND."""
    supported = cdav.SupportedCalendarComponentSet()
    response = calendar.get_properties(
        [dav.DisplayName(), ical.CalendarColor(), supported],
        parse_response_xml=False,
    )
    # Depth 0: the only entry is the calendar itself.
    props = next(iter(response.find_objects_and_props().values()), {})

    def text(tag):
        element = props.get(tag)
        return (element.text or "").strip() if element is not None else ""

    comps = props.get(supported.tag)
    # Reminder lists are calendars too, but only hold VTODOs.
    events = comps is None or any(c.get("name") == "VEVENT" for c in comps)
    return text(dav.DisplayName.tag), ical_color(
        text(ical.CalendarColor.tag)), events


def icloud_events(conf, start, end):
    client = caldav.DAVClient(
        url=ICLOUD_URL,
        username=conf["username"],
        password=conf["password"],
        timeout=TIMEOUT,
    )
    # caldav 3 talks to iCloud through niquests, which upgrades to HTTP/3 when
    # the server offers it; iCloud drops those QUIC connections now and then
    # ("HTTP/3 connection terminated"), failing about one fetch in three.
    # HTTP/2 over TCP never has.
    if hasattr(client.session, "quic_cache_layer"):
        client.session = type(client.session)(disable_http3=True)
    try:
        calendars = client.principal().calendars()
    except AuthorizationError:
        raise SourceError(
            "Sign-in failed: check the Apple ID and app-specific password")
    except Exception as e:
        raise SourceError(f"Couldn't reach iCloud ({type(e).__name__})")

    # Padded by a day each side: the range is in local dates.
    begin = datetime.combine(start, datetime.min.time(), timezone.utc)
    until = datetime.combine(end, datetime.min.time(), timezone.utc)
    begin -= timedelta(days=1)
    until += timedelta(days=1)
    events, failed = [], []
    for calendar in calendars:
        name = ""
        try:
            name, color, has_events = calendar_info(calendar)
            if not has_events:
                continue
            found = calendar.search(
                start=begin, end=until, event=True, expand=True)
        except Exception:
            failed.append(name or calendar.url.path)
            continue
        for item in found:
            vevent = item.icalendar_component
            if str(vevent.get("STATUS", "")).upper() == "CANCELLED":
                continue
            first, all_day = ical_time(vevent.start)
            last, _ = ical_time(vevent.end)
            events.append({
                "title": str(vevent.get("SUMMARY", "")) or "(No title)",
                "detail": str(vevent.get("LOCATION", "")),
                "start": first,
                "end": last,
                "allDay": all_day,
                "source": "icloud",
                "calendar": name or "iCloud",
                "color": color,
                "done": False,
            })
    errors = [f"Couldn't read {', '.join(failed)}"] if failed else []
    return events, errors


SOURCES = {
    "icloud": (icloud_events, ["username", "password"]),
    "sonarr": (sonarr_events, ["url", "apiKey"]),
    "radarr": (radarr_events, ["url", "apiKey"]),
}


def main():
    try:
        start, end = (date.fromisoformat(arg) for arg in sys.argv[1:3])
        if len(sys.argv) != 3 or end <= start:
            raise ValueError
    except ValueError:
        print("usage: quickshell-calendar START END (ISO dates)",
              file=sys.stderr)
        return 2

    result = {"configured": False, "events": [], "errors": []}
    try:
        with open(config_path()) as f:
            config = json.load(f)
    except FileNotFoundError:
        print(json.dumps(result))
        return 0
    except (OSError, ValueError) as e:
        config = e
    result["configured"] = True
    if not isinstance(config, dict):
        problem = config if isinstance(config, Exception) else "not an object"
        result["errors"].append(
            {"source": "config", "message": f"calendars.json: {problem}"})
        print(json.dumps(result))
        return 0

    def failed(source, message):
        result["errors"].append({"source": source, "message": message})

    # Secrets first, one pass-cli call at a time under quickshell-pass's lock;
    # signed out, every pass:// source is skipped and reported once, as
    # passSignedOut, rather than as one identical error per source.
    sources = {}
    lock = None
    for source, (fetch, keys) in SOURCES.items():
        if source not in config:
            continue
        section = config[source]
        try:
            if lock is None and isinstance(section, dict) and any(
                    str(section.get(key, "")).startswith("pass://")
                    for key in keys):
                lock = pass_lock()
            sources[source] = (fetch, settings(section, keys))
        except PassSignedOut:
            result["passSignedOut"] = True
        except SourceError as e:
            failed(source, str(e))
    if lock is not None:
        lock.close()

    # Then every source in parallel.
    with ThreadPoolExecutor() as pool:
        futures = {
            source: pool.submit(fetch, values, start, end)
            for source, (fetch, values) in sources.items()
        }
    for source, future in futures.items():
        try:
            events, problems = future.result()
        except SourceError as e:
            problems = [str(e)]
        except Exception as e:
            # Exception texts can carry request details; the type is enough.
            problems = [f"Unexpected error ({type(e).__name__})"]
        else:
            result["events"].extend(events)
        for message in problems:
            failed(source, message)

    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
