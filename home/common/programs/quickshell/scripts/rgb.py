# OpenRGB lighting for the control panel (services/Lighting.qml), as a client
# of the system's OpenRGB SDK server (hosts/common/desktop/rgb.nix).
#
#   quickshell-rgb status       the lights and the looks, as JSON
#   quickshell-rgb set LOOK     a look below, or color:RRGGBB
#   quickshell-rgb serve        the engine (quickshell-rgb.service)
#
# Only Direct mode reaches atlas's hardware: the Aura and NZXT Hue 2
# controllers ignore the server's built-in modes and the RAM goes dark in one.
# So every look is drawn LED by LED: `set` records the choice in the state
# dir; the engine applies it to every device, again after the server restarts
# (boot, VFIO VM handing devices back), redrawing moving looks 20x/s.
#
# QMK keyboards follow over raw HID. With SignalRGB's protocol in the firmware
# (the K8 Pro runs SRGBmods' Keychron QMK build) every key is drawn from its
# position; stock VIA firmware takes one colour for the board (the look's at
# the case's middle), RAM only (VIA set, never save).
#
# `status` prints one JSON object:
#   {"running": bool,      the server answered
#    "engine": bool,       quickshell-rgb.service is running
#    "devices": [{"name", "leds"}],
#    "look": str,          the chosen look's id ("" for none)
#    "looks": [{"id", "name", "kind": "color"|"effect"|"off",
#               "colors": ["#rrggbb", …]}],   its swatch
#    "error": str}         "" unless something failed

import colorsys
import glob
import json
import math
import os
import random
import re
import select
import signal
import subprocess
import sys
import time
from pathlib import Path

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

STATE = Path(os.environ.get("XDG_STATE_HOME",
                            Path.home() / ".local/state")) / "quickshell-rgb"
LOOK_FILE = STATE / "look.json"
# Moving looks redraw at this rate; unchanged devices aren't sent to (the
# server writes every frame to hardware, the RAM over SMBus).
FPS = 20


def rgb(hex_):
    hex_ = hex_.lstrip("#")
    return tuple(int(hex_[i:i + 2], 16) / 255 for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def ramp(stops, t):
    """A colour along evenly spaced stops, wrapping round."""
    t = (t % 1) * len(stops)
    i = int(t)
    return mix(stops[i], stops[(i + 1) % len(stops)], t - i)


def hue(h, s=1.0, v=1.0):
    return colorsys.hsv_to_rgb(h % 1, s, v)


# Each LED is drawn from (t, x, u, ring, i):
#   t      seconds since the look went on
#   x      the zone's place among all zones, 0..1 (RAM, board, then fans)
#   u      the LED's place along its zone, 0..1
#   ring   its zone is a fan's ring (u goes round it) rather than a strip
#   i      a stable per-LED number, for noise
def solid(colour):
    c = rgb(colour)
    return lambda t, x, u, ring, i: c


def spectrum(t, x, u, ring, i):
    return hue(t / 60)


def rainbow(t, x, u, ring, i):
    return hue(u + x * 0.5 - t / 8)


AURORA = [rgb("12d18e"), rgb("0b8f8a"), rgb("2b5fd9"), rgb("8a3ffc"),
          rgb("1fbf6f")]


def aurora(t, x, u, ring, i):
    a = math.sin(t / 7 + x * 4 + u * 2.2) + math.sin(t / 11 - u * 5 + x * 2)
    glow = 0.55 + 0.45 * math.sin(t / 3 + i * 0.7 + x * 3)
    return tuple(c * (0.35 + 0.65 * glow)
                 for c in ramp(AURORA, (a + 2) / 4 + t / 90))


HEARTH = [rgb("ff2a00"), rgb("ff5a00"), rgb("ff8c10"), rgb("ffb020")]
_flame = {}


def hearth(t, x, u, ring, i):
    # Each LED wanders towards a new heat now and then; quick flickers on top.
    level, target = _flame.get(i, (0.6, 0.6))
    if random.random() < 0.06:
        target = random.uniform(0.25, 1.0)
    level += (target - level) * 0.18
    _flame[i] = (level, target)
    flicker = 0.85 + 0.15 * math.sin(t * 23 + i * 1.7)
    c = ramp(HEARTH[:-1], level * 0.66) if level < 0.95 else HEARTH[-1]
    return tuple(v * level * flicker for v in c)


TIDE = [rgb("001a66"), rgb("0047b3"), rgb("00a3cc"), rgb("40e0d0")]


def tide(t, x, u, ring, i):
    w = 0.5 + 0.5 * math.sin(t / 2.5 - x * 6 - u * (6.283 if ring else 3))
    return ramp(TIDE[:-1], w * 0.66) if w < 0.92 else mix(TIDE[2], TIDE[3],
                                                          (w - 0.92) / 0.08)


SYNTH_A, SYNTH_B = rgb("ff2bd6"), rgb("00e5ff")


def synthwave(t, x, u, ring, i):
    if ring:
        # Two halves of each fan chasing round, the fans out of step.
        w = 0.5 + 0.5 * math.sin((u + x - t / 4) * 6.283)
    else:
        w = 0.5 + 0.5 * math.sin(u * 3.14 + t / 2 + x * 3)
    return mix(SYNTH_A, SYNTH_B, w)


SUNSET = [rgb("ff9a3c"), rgb("ff4f6d"), rgb("b23aee"), rgb("4b2aad")]


def sunset(t, x, u, ring, i):
    # Still: amber at one end of the case to violet at the other.
    p = x * 0.75 + u * 0.25
    return ramp(SUNSET, p * 0.75)


def gilt_breathe(t, x, u, ring, i):
    v = 0.25 + 0.75 * (0.5 - 0.5 * math.cos(t / 6 * 6.283))
    return tuple(c * v for c in rgb("c9a24f"))


def off(t, x, u, ring, i):
    return (0, 0, 0)


# id, name, kind, swatch, draw, moving
LOOKS = [
    ("gilt", "Gilt", "color", ["#c9a24f"], solid("c9a24f"), False),
    ("warm", "Warm white", "color", ["#ffb46b"], solid("ffb46b"), False),
    ("white", "White", "color", ["#ffffff"], solid("ffffff"), False),
    ("ice", "Ice blue", "color", ["#8fb0d3"], solid("8fb0d3"), False),
    ("ember", "Ember", "color", ["#e0603a"], solid("e0603a"), False),
    ("aurora", "Aurora", "effect", ["#12d18e", "#2b5fd9", "#8a3ffc"],
     aurora, True),
    ("hearth", "Hearth", "effect", ["#ff2a00", "#ff8c10", "#ffb020"],
     hearth, True),
    ("tide", "Tide", "effect", ["#001a66", "#00a3cc", "#40e0d0"], tide, True),
    ("synthwave", "Synthwave", "effect", ["#ff2bd6", "#00e5ff"],
     synthwave, True),
    ("sunset", "Sunset", "effect", ["#ff9a3c", "#ff4f6d", "#b23aee"],
     sunset, False),
    ("breathe", "Gilt breathing", "effect", ["#c9a24f", "#2a2210"],
     gilt_breathe, True),
    ("rainbow", "Rainbow", "effect", ["#ff0000", "#00ff00", "#0000ff"],
     rainbow, True),
    ("spectrum", "Spectrum", "effect", ["#ff0000", "#ffff00", "#00ffff"],
     spectrum, True),
    ("off", "Off", "off", [], off, False),
]
BY_ID = {look[0]: look for look in LOOKS}


def resolve(look_id):
    """The look's (draw, moving), or None for no look."""
    if look_id in BY_ID:
        return BY_ID[look_id][4], BY_ID[look_id][5]
    match = re.fullmatch(r"color:([0-9a-f]{6})", look_id or "")
    if match:
        return solid(match.group(1)), False
    return None


def read_look():
    try:
        return json.loads(LOOK_FILE.read_text()).get("look", "")
    except (OSError, ValueError):
        return ""


def write_look(look_id):
    STATE.mkdir(parents=True, exist_ok=True)
    tmp = LOOK_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps({"look": look_id}))
    tmp.replace(LOOK_FILE)


def layout(client):
    """Each device with its LEDs' (x, u, ring, i), zone by zone."""
    zones = [(device, zone) for device in client.devices
             for zone in device.zones if len(zone.leds) > 0]
    out, i = [], 0
    for device in client.devices:
        leds = []
        for zone in device.zones:
            n = len(zone.leds)
            if n == 0:
                continue
            x = zones.index((device, zone)) / max(1, len(zones) - 1)
            # A fan's ring is a zone of a fan controller; RAM and the board
            # are strips.
            ring = "Hue" in zone.name or "Fan" in zone.name
            for k in range(n):
                leds.append((x, k / n if ring else k / max(1, n - 1), ring,
                             i))
                i += 1
        out.append((device, leds))
    return out


def colour(c):
    return RGBColor(*(max(0, min(255, round(v * 255))) for v in c))


def draw(lights, fn, t, sent):
    for device, leds in lights:
        if not leds:
            continue
        frame = [colour(fn(t, *led)) for led in leds]
        key = id(device)
        if sent.get(key) != frame:
            device.set_colors(frame, fast=True)
            sent[key] = frame


VIA_USAGE_PAGE = bytes([0x06, 0x60, 0xFF])  # report descriptor's first item
VIA_RATE = 0.1  # seconds between a moving look's one-colour updates

# Each key's (column, row) by LED index for SignalRGB-protocol boards, from
# SRGBmods' plugin (qmk-plugins).
KEY_POSITIONS = {
    # Keychron K8 Pro ISO RGB: a 17x6 TKL.
    (0x3434, 0x0281): (
        [(c, 0) for c in (*range(13), 14, 15, 16)]
        + [(c, 1) for c in range(17)]
        + [(c, 2) for c in range(17)]
        + [(c, 3) for c in (*range(12), 13)]
        + [(c, 4) for c in (*range(12), 13, 15)]
        + [(c, 5) for c in (0, 1, 2, 6, 10, 11, 12, 13, 14, 15, 16)]),
}


class Keyboard:
    """A QMK keyboard's lighting, through its raw HID interface."""

    def __init__(self, node, name, ids):
        self.node, self.name = node, name
        self.fd = os.open(node, os.O_RDWR)
        self.sent, self.at = None, 0.0
        self.keys = KEY_POSITIONS.get(ids)
        # SignalRGB's protocol: 0x22 answers with its version, 0x25 hands the
        # LEDs to the host, 0x24 sets up to 9 of them from an index.
        total = self.ask([0x27]) if self.keys and \
            self.ask([0x22]) is not None else None
        if total is not None and total[1] == len(self.keys):
            self.ask([0x25])
            width = max(c for c, _ in self.keys) or 1
            height = max(r for _, r in self.keys) or 1
            # x across the board, u down its rows, so a look sweeps over it
            # as over the case.
            self.leds = [(c / width, r / height, False, 5000 + k)
                         for k, (c, r) in enumerate(self.keys)]
            return
        self.keys = None
        version = self.ask([0x01])
        self.via = (version[1] << 8 | version[2]) if version else 0
        # VIA lighting values: brightness, effect, hue, saturation. Protocol
        # 12 put them on channel 3 (QMK RGB matrix) as 1, 2, 4 (earlier:
        # 0x80, 0x81, 0x83). Effect 1 is a solid colour.
        self.value = (lambda v: [0x07, 0x03, v]) if self.via >= 12 else \
            (lambda v: [0x07, {1: 0x80, 2: 0x81, 4: 0x83}[v]])
        self.ask(self.value(2) + [0x01])

    def ask(self, data):
        """Sends a report; its reply, or None when none came."""
        os.write(self.fd, bytes([0]) + bytes(data) + bytes(32 - len(data)))
        for _ in range(4):
            if not select.select([self.fd], [], [], 0.2)[0]:
                return None
            reply = os.read(self.fd, 32)
            if reply[0] == data[0]:
                return reply
        return None

    def show(self, fn, t, moving):
        if self.keys:
            frame = [colour(fn(t, *led)) for led in self.leds]
            if frame == self.sent:
                return
            for start in range(0, len(frame), 9):
                chunk = frame[start:start + 9]
                data = [0x24, start, len(chunk)]
                for c in chunk:
                    data += [c.red, c.green, c.blue]
                os.write(self.fd, bytes([0]) + bytes(data)
                         + bytes(32 - len(data)))
            self.sent = frame
            return
        now = time.monotonic()
        if moving and now - self.at < VIA_RATE:
            return
        h, s, v = colorsys.rgb_to_hsv(*fn(t, 0.5, 0.5, False, -1))
        want = (round(h * 255), round(s * 255), round(v * 255))
        if want != self.sent:
            if self.sent is None or want[:2] != self.sent[:2]:
                self.ask(self.value(4) + list(want[:2]))
            if self.sent is None or want[2] != self.sent[2]:
                self.ask(self.value(1) + [want[2]])
            self.sent = want
        self.at = now

    def drain(self):
        # SignalRGB's 0x24 is answered too; drain replies so they don't pile.
        while select.select([self.fd], [], [], 0)[0]:
            os.read(self.fd, 32)

    def close(self):
        try:
            if self.keys:
                self.ask([0x26])  # the board's own lighting back
        except OSError:
            pass
        try:
            os.close(self.fd)
        except OSError:
            pass


def find_keyboards():
    """(node, name, (vendor, product)) of each QMK raw HID interface."""
    found = []
    for path in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        try:
            with open(f"{path}/device/report_descriptor", "rb") as f:
                if f.read(3) != VIA_USAGE_PAGE:
                    continue
            with open(f"{path}/device/uevent") as f:
                uevent = dict(line.split("=", 1) for line in
                              f.read().splitlines() if "=" in line)
        except OSError:
            continue
        _, vendor, product = (uevent.get("HID_ID", "0:0:0").split(":")
                              + ["0", "0"])[:3]
        found.append((f"/dev/{os.path.basename(path)}",
                      uevent.get("HID_NAME", "Keyboard"),
                      (int(vendor, 16), int(product, 16))))
    return found


def connect():
    """A client once the server has settled on its devices, else None."""
    try:
        client = OpenRGBClient(name="quickshell-rgb")
    except Exception:
        return None
    # Detection adds devices one at a time with the server already up: wait
    # until two readings a second apart agree (a minute at most).
    seen = None
    for _ in range(60):
        try:
            client.update()
        except Exception:
            return None
        names = [d.name for d in client.devices]
        if names and names == seen:
            break
        seen = names
        time.sleep(1)
    try:
        for device in client.devices:
            device.set_mode("Direct")
    except Exception:
        return None
    return client


def serve():
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    # OpenRGB and keyboards come and go: each is retried every few seconds
    # while missing; the look applies to whatever is present.
    client, lights = None, []
    keyboards = {}
    try:
        run(client, lights, keyboards)
    finally:
        for keyboard in keyboards.values():
            keyboard.close()


def run(client, lights, keyboards):
    current, started, drawn, sent = None, 0.0, False, {}
    last_check = 0.0
    while True:
        now = time.monotonic()
        if now - last_check > 5:
            last_check = now
            if client is None:
                client = connect()
                lights = layout(client) if client else []
                drawn = False
                sent.clear()
            else:
                try:
                    # A server that went away shows on the next request.
                    client.update()
                    if [d.name for d in client.devices] != \
                            [d.name for d, _ in lights]:
                        raise ConnectionError("devices changed")
                except Exception:
                    try:
                        client.disconnect()
                    except Exception:
                        pass
                    client, lights = None, []
            for node, name, ids in find_keyboards():
                if node not in keyboards:
                    try:
                        keyboards[node] = Keyboard(node, name, ids)
                    except (OSError, TypeError):
                        pass
        look_id = read_look()
        if look_id != current:
            current, started, drawn = look_id, now, False
            sent.clear()
            _flame.clear()
            for keyboard in keyboards.values():
                keyboard.sent = None
        look = resolve(current)
        if look is not None:
            fn, moving = look
            t = now - started
            if client is not None and (moving or not drawn):
                try:
                    draw(lights, fn, t, sent)
                    drawn = True
                except Exception:
                    last_check = 0.0
            for node, keyboard in list(keyboards.items()):
                try:
                    keyboard.drain()
                    keyboard.show(fn, t, moving)
                # Unplugged, or switched to Bluetooth.
                except OSError:
                    keyboard.close()
                    del keyboards[node]
        time.sleep(1 / FPS if look and look[1] else 0.2)


def engine_running():
    try:
        return subprocess.run(
            ["systemctl", "--user", "is-active", "--quiet",
             "quickshell-rgb.service"], timeout=5).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def status(error=""):
    result = {
        "running": False,
        "engine": engine_running(),
        "devices": [],
        "look": read_look(),
        "looks": [{"id": i, "name": n, "kind": k, "colors": c}
                  for i, n, k, c, _, _ in LOOKS],
        "error": error,
    }
    client = None
    try:
        client = OpenRGBClient(name="quickshell-rgb status")
        result["devices"] = [{"name": d.name, "leds": len(d.leds)}
                             for d in client.devices]
        result["running"] = True
    # Refused = server not up; anything else = it went away or sent what
    # openrgb-python can't read.
    except Exception as e:
        if client is not None or not isinstance(e, OSError):
            result["error"] = result["error"] or \
                f"OpenRGB stopped answering: {e}"
    finally:
        if client is not None:
            client.disconnect()
    result["devices"] += [
        {"name": name, "leds": len(KEY_POSITIONS.get(ids, [None]))}
        for _, name, ids in find_keyboards()]
    if not result["engine"] and not result["error"]:
        result["error"] = "The lighting engine (quickshell-rgb.service) " \
            "isn't running."
    print(json.dumps(result))


def main(argv):
    match argv[1:]:
        case [] | ["status"]:
            status()
        case ["set", look_id] if resolve(look_id.lower()) is not None:
            write_look(look_id.lower())
            status()
        case ["serve"]:
            serve()
        case _:
            print("usage: quickshell-rgb status|set LOOK|serve",
                  file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
