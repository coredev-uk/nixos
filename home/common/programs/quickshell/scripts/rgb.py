# OpenRGB lighting for the control panel's Lighting section
# (config/services/Lighting.qml), as a client of the system's OpenRGB SDK
# server (openrgb.service, hosts/common/desktop/rgb.nix).
#
#   quickshell-rgb status
#   quickshell-rgb color RRGGBB     every device in one colour
#   quickshell-rgb off              every device off
#   quickshell-rgb spectrum         every device slowly cycling the hues
#   quickshell-rgb profile NAME     a profile saved in OpenRGB
#
# Through openrgb-python rather than the openrgb CLI: the CLI asks for the
# profile list without waiting for the answer, so it sometimes lists none,
# and it starts a Qt application per call. openrgb-python speaks protocol 4,
# which the server still serves.
#
# Every command prints the state after it, as one JSON object:
#   {"running": bool,          the server answered, all through
#    "server": str,            openrgb.service's invocation id ("" if none):
#                              a new one is a server with its devices back
#                              in their own lighting
#    "devices": [{"name", "mode", "state"}],
#       state: the mode and its colours, to tell when something else
#       changed the lighting
#    "profiles": [names],
#    "skipped": [names],       devices the command had no mode for
#    "error": str}             "" unless something failed

import hashlib
import json
import re
import subprocess
import sys
import time

from openrgb import OpenRGBClient
from openrgb.utils import ModeColors, ModeFlags, RGBColor

# A colour cycle, calmest first: the whole device fading through the hues
# before a wave running along it.
SPECTRUM_MODES = [
    "Spectrum Cycle",
    "Color Cycle",
    "Colour Cycle",
    "Rainbow",
    "Rainbow Wave",
    "Spectrum",
    "Color Wave",
]
# Of the way from the mode's slowest to its fastest.
SPECTRUM_SPEED = 0.25


def find_mode(device, names):
    lower = {mode.name.lower(): mode for mode in device.modes}
    for name in names:
        if name.lower() in lower:
            return lower[name.lower()]
    return None


def set_colour(device, mode, colour):
    if ModeFlags.HAS_MODE_SPECIFIC_COLOR in mode.flags:
        mode.color_mode = ModeColors.MODE_SPECIFIC
        mode.colors = [colour] * max(1, mode.colors_min or 1)
        device.set_mode(mode)
    else:
        device.set_mode(mode)
        device.set_color(colour)


# Each returns False for a device it has no mode for.
def colour_preset(colour):
    def apply(device):
        mode = find_mode(device, ["Static", "Direct"])
        if mode is None:
            return False
        set_colour(device, mode, colour)
        return True
    return apply


def off(device):
    mode = find_mode(device, ["Off"])
    if mode is None:
        return colour_preset(RGBColor(0, 0, 0))(device)
    device.set_mode(mode)
    return True


def spectrum(device):
    mode = find_mode(device, SPECTRUM_MODES)
    if mode is None:
        return False
    if ModeFlags.HAS_SPEED in mode.flags:
        # speed_max is below speed_min on devices that count down.
        mode.speed = round(mode.speed_min
                           + (mode.speed_max - mode.speed_min)
                           * SPECTRUM_SPEED)
    device.set_mode(mode)
    return True


def apply_preset(client, apply):
    skipped, errors = [], []
    for device in client.devices:
        try:
            if not apply(device):
                skipped.append(device.name)
        # A mode whose ranges don't add up fails openrgb-python's checks.
        except (ValueError, TypeError) as error:
            errors.append(f"{device.name}: {error}")
    return skipped, errors


def state(device):
    mode = device.modes[device.active_mode]
    colours = mode.colors if mode.color_mode == ModeColors.MODE_SPECIFIC \
        else device.colors
    digest = hashlib.sha1(
        b"".join(colour.pack() for colour in colours or [])).hexdigest()
    return f"{mode.name} {digest[:12]}"


def snapshot(client):
    client.update()
    return [state(device) for device in client.devices]


# The server applies a profile after answering, so wait (a second at most)
# for the devices to change before reading them.
def load_profile(client, name):
    if name not in (profile.name for profile in client.profiles):
        return [], [f"OpenRGB has no profile named {name}"]
    before = snapshot(client)
    client.load_profile(name)
    for _ in range(10):
        time.sleep(0.1)
        if snapshot(client) != before:
            break
    return [], []


def command(argv):
    match argv[1:]:
        case [] | ["status"]:
            return None
        case ["color", value] if re.fullmatch(r"[0-9A-Fa-f]{6}", value):
            colour = RGBColor.fromHEX(value)
            return lambda client: apply_preset(client, colour_preset(colour))
        case ["off"]:
            return lambda client: apply_preset(client, off)
        case ["spectrum"]:
            return lambda client: apply_preset(client, spectrum)
        case ["profile", name]:
            return lambda client: load_profile(client, name)
    raise ValueError


def server_id():
    try:
        return subprocess.run(
            ["systemctl", "show", "--value", "--property=InvocationID",
             "openrgb.service"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def main(argv):
    try:
        action = command(argv)
    except ValueError:
        print("usage: quickshell-rgb status|color RRGGBB|off|spectrum|"
              "profile NAME", file=sys.stderr)
        return 2
    result = {"running": False, "server": server_id(), "devices": [],
              "profiles": [], "skipped": [], "error": ""}
    client = None
    try:
        client = OpenRGBClient(name="Quickshell")
        if action is not None:
            skipped, errors = action(client)
            result["skipped"] = skipped
            result["error"] = "; ".join(errors)
        client.update()
        result["devices"] = [
            {"name": device.name,
             "mode": device.modes[device.active_mode].name,
             "state": state(device)}
            for device in client.devices]
        result["profiles"] = [profile.name for profile in client.profiles]
        result["running"] = True
    # Refused is a server that isn't up; anything else, one that went away
    # or sent what openrgb-python can't read.
    except Exception as error:
        if client is not None or not isinstance(error, OSError):
            result["error"] = f"OpenRGB stopped answering: {error}"
    finally:
        if client is not None:
            client.disconnect()
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
