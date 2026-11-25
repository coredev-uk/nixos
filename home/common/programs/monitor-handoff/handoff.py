# Moves the primary monitor's workspaces to the second screen while it shows
# another input, and back when it shows the PC again (default.nix has why).
# Reads the monitor's Input Source over i2c-dev itself: ddcutil costs ~0.1 s
# of CPU per read, too much to poll fast enough for a quick switch back.
# argv[1] is the JSON config from default.nix.

import fcntl
import json
import os
import re
import subprocess
import sys
import time

CONFIG = json.load(open(sys.argv[1]))
OUTPUT = CONFIG["output"]
PC_INPUT = CONFIG["pcInput"]
SAVED = os.path.join(
    os.environ["XDG_RUNTIME_DIR"], "monitor-handoff-workspace"
)

# Seconds between reads: parked, the switch back is seen within POLL_AWAY.
# A read costs ~20 ms of CPU (NVIDIA's I2C is bit-banged).
POLL_HOME = 0.5
POLL_AWAY = 0.25
# Unanswered reads in a row that mean another input.
MISSES = 4
# DDC drops out for a few seconds after a modeset or DPMS wake, and after a
# resume from suspend; misses then don't count.
SETTLE = 10
SETTLE_RESUME = 30

I2C_SLAVE_FORCE = 0x0706  # the ddcci driver holds the address
DDC_ADDR = 0x37
VCP_INPUT = 0x60


def ddc_bus():
    # ddcutil lists the bus even while the monitor shows another input.
    out = subprocess.run(
        [CONFIG["ddcutil"], "detect", "--brief"],
        capture_output=True,
        text=True,
    ).stdout
    bus = None
    for line in out.splitlines():
        m = re.match(r"\s*I2C bus:\s+/dev/i2c-(\d+)", line)
        if m:
            bus = m.group(1)
        elif re.match(rf"\s*DRM connector:\s+\S+-{re.escape(OUTPUT)}$", line):
            return bus
    return None


def read_input(fd):
    # DDC/CI Get VCP Feature; None when the monitor doesn't answer.
    request = [0x51, 0x82, 0x01, VCP_INPUT]
    check = DDC_ADDR << 1
    for b in request:
        check ^= b
    try:
        os.write(fd, bytes(request + [check]))
        time.sleep(0.04)
        reply = os.read(fd, 11)
    except OSError:
        return None
    check = 0x50
    for b in reply[:-1]:
        check ^= b
    if (
        len(reply) != 11
        or reply[1:5] != bytes([0x88, 0x02, 0x00, VCP_INPUT])
        or reply[10] != check
    ):
        return None
    return reply[9]


def hyprctl(*args):
    return subprocess.run(
        ["hyprctl", *args], capture_output=True, text=True
    ).stdout


def monitor(mirrors=True):
    # Plain `monitors` leaves out mirrors.
    args = ["-j", "monitors"] + (["all"] if mirrors else [])
    try:
        monitors = json.loads(hyprctl(*args))
    except ValueError:
        return None
    return next((m for m in monitors if m["name"] == OUTPUT), None)


def park(mon):
    # A config reload drops the mirror (hyprland.lua's rule has none); the
    # re-park keeps the first save.
    if not os.path.exists(SAVED):
        with open(SAVED, "w") as f:
            f.write(str(mon["activeWorkspace"]["id"]))
    hyprctl("eval", CONFIG["park"])
    print(f"{OUTPUT} shows another input: mirroring it", flush=True)


def restore():
    hyprctl("eval", CONFIG["restore"])
    for _ in range(250):
        if monitor(mirrors=False) is not None:
            break
        time.sleep(0.02)
    try:
        with open(SAVED) as f:
            last = int(f.read())
    except (OSError, ValueError):
        last = 0
    ids = ", ".join(str(w) for w in CONFIG["workspaces"])
    hyprctl("eval", f"""
        for _, id in ipairs({{ {ids} }}) do
          if hl.get_workspace(id) then
            hl.dispatch(hl.dsp.workspace.move({{
              workspace = id, monitor = "{OUTPUT}" }}))
          end
        end
        local last = hl.get_workspace({last})
        if last then hl.dispatch(hl.dsp.focus({{ workspace = last.id }})) end
    """)
    forget()
    print(f"{OUTPUT} shows the PC again: restored", flush=True)


def forget():
    if os.path.exists(SAVED):
        os.remove(SAVED)


def slept():
    # Grows by the time spent suspended.
    return time.clock_gettime(time.CLOCK_BOOTTIME) - time.monotonic()


def main():
    bus = ddc_bus()
    if bus is None:
        sys.exit(f"no DDC bus for {OUTPUT}")
    fd = os.open(f"/dev/i2c-{bus}", os.O_RDWR)
    fcntl.ioctl(fd, I2C_SLAVE_FORCE, DDC_ADDR)

    misses = 0
    settle = time.monotonic() + SETTLE
    asleep = slept()
    while True:
        now = time.monotonic()
        if slept() - asleep > 1:
            settle = now + SETTLE_RESUME
        asleep = slept()

        mon = monitor()
        if mon is None or not mon["dpmsStatus"]:
            misses = 0
            settle = now + SETTLE
            time.sleep(POLL_HOME)
            continue
        mirrored = mon["mirrorOf"] != "none"

        if read_input(fd) == PC_INPUT:
            misses = 0
            if mirrored:
                restore()
                settle = time.monotonic() + SETTLE
            else:
                forget()
        elif not mirrored and now >= settle:
            misses += 1
            # A save means the mirror was dropped while away: re-park at once.
            if misses >= MISSES or os.path.exists(SAVED):
                park(mon)
                misses = 0
        time.sleep(POLL_AWAY if mirrored else POLL_HOME)


main()
