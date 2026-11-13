# The NZXT Kraken Elite's screen (1e71:300c) as a temperature gauge: CPU,
# GPU and coolant, drawn here and pushed through liquidctl's API whenever a
# reading changes (at most every UPDATE seconds, and every REFRESH seconds
# regardless). NZXT CAM doesn't run on Linux, and liquidctl only uploads
# still pictures; this streams frames the way CAM does (see MAGIC below).
#
# Readings: the CPU's Tctl (k10temp) and the coolant (the kernel's
# kraken2023elite hwmon driver) from sysfs, the GPU from nvidia-smi. A source
# that doesn't answer shows a dash.
#
# Stopped, it puts the cooler's own liquid-temperature screen back.

import glob
import os
import shutil
import signal
import subprocess
import sys
import time

from liquidctl import find_liquidctl_devices
from PIL import Image, ImageDraw, ImageFont

FONT_DIR = os.environ["KRAKEN_LCD_FONTS"]
UPDATE = 2
REFRESH = 30
SIZE = 640

GROUND = (21, 25, 32)
RULE = (54, 61, 73)
TEXT = (236, 229, 211)
TEXT2 = (169, 164, 147)
GILT = (201, 162, 79)
CAUTION = (224, 149, 79)
ALERT = (224, 108, 90)


def font(weight, size):
    return ImageFont.truetype(
        os.path.join(FONT_DIR, f"AtkinsonHyperlegibleNext-{weight}.otf"), size)


BIG = font("Bold", 150)
MID = font("Bold", 64)
LABEL = font("Regular", 30)
SMALL = font("Regular", 26)


def hwmon(name, sensor="temp1_input"):
    for path in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            with open(f"{path}/name") as f:
                if f.read().strip() != name:
                    continue
            with open(f"{path}/{sensor}") as f:
                return int(f.read()) / 1000
        except OSError:
            continue
    return None


NVIDIA_SMI = (shutil.which("nvidia-smi")
              or "/run/current-system/sw/bin/nvidia-smi")


def gpu():
    try:
        out = subprocess.run(
            [NVIDIA_SMI, "--query-gpu=temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=3)
        return float(out.stdout.split()[0]) if out.returncode == 0 else None
    except (OSError, subprocess.SubprocessError, ValueError, IndexError):
        return None


def readings():
    return {"cpu": hwmon("k10temp"), "gpu": gpu(),
            "liquid": hwmon("kraken2023elite")}


def tone(value, warm, hot):
    if value is None:
        return TEXT2
    return ALERT if value >= hot else CAUTION if value >= warm else GILT


def centred(draw, y, text, face, fill):
    w = draw.textlength(text, font=face)
    draw.text(((SIZE - w) / 2, y), text, font=face, fill=fill)


def arc(draw, start, end, value, low, high, fill, from_end=False):
    """A gauge along the rim from start to end degrees (clockwise from 3
    o'clock), filled to where value sits between low and high: from start,
    or from end."""
    box = (28, 28, SIZE - 28, SIZE - 28)
    draw.arc(box, start, end, fill=RULE, width=18)
    if value is not None:
        t = max(0.0, min(1.0, (value - low) / (high - low)))
        if t > 0:
            span = (end - start) * t
            draw.arc(box, end - span if from_end else start,
                     end if from_end else start + span, fill=fill, width=18)


def render(r):
    image = Image.new("RGB", (SIZE, SIZE), GROUND)
    draw = ImageDraw.Draw(image)
    cpu, gpu_, liquid = r["cpu"], r["gpu"], r["liquid"]

    # CPU up the left rim, GPU up the right, both from the bottom.
    arc(draw, 140, 220, cpu, 30, 95, tone(cpu, 75, 88))
    arc(draw, 320, 400, gpu_, 30, 90, tone(gpu_, 75, 85), from_end=True)

    centred(draw, 150, "CPU", LABEL, TEXT2)
    centred(draw, 180, "—" if cpu is None else f"{cpu:.0f}°", BIG,
            tone(cpu, 75, 88))

    for x, label, value, fill in (
            (200, "GPU", gpu_, tone(gpu_, 75, 85)),
            (440, "Liquid", liquid, tone(liquid, 40, 45))):
        text = "—" if value is None else (
            f"{value:.1f}°" if label == "Liquid" else f"{value:.0f}°")
        w = draw.textlength(text, font=MID)
        draw.text((x - w / 2, 410), text, font=MID, fill=fill)
        w = draw.textlength(label, font=SMALL)
        draw.text((x - w / 2, 485), label, font=SMALL, fill=TEXT2)

    draw.line((SIZE / 2, 415, SIZE / 2, 510), fill=RULE, width=2)
    return image


def shown(r):
    """What the picture shows: a change here is worth an upload."""
    return (None if r["cpu"] is None else round(r["cpu"]),
            None if r["gpu"] is None else round(r["gpu"]),
            None if r["liquid"] is None else round(r["liquid"], 1))


# NZXT CAM's live mode, as captured from it on this cooler (1e71:300c) by
# github.com/KhalloufHassan/kraken-elite-screen-manager: after one handshake,
# every frame is 640x640 raw BGR streamed behind a short header, with no
# per-frame bucket setup. liquidctl's static upload instead writes a picture
# into one of the screen's 16 memory buckets and switches to it, clearing all
# of them (and showing the liquid screen) once they're used: that flickers
# and cycles on a gauge.
MAGIC = [0x12, 0xFA, 0x01, 0xE8, 0xAB, 0xCD, 0xEF, 0x98, 0x76, 0x54, 0x32,
         0x10]
URB = 245760  # CAM's bulk transfer size


def command(device, data, timeout=150):
    """Sends a control report and waits for its own reply; the cooler also
    sends a status report about once a second, which isn't one."""
    device._write(data)
    for _ in range(24):
        try:
            msg = device.device.read(64, timeout=timeout)
        except Exception:
            return None
        if msg[0] == data[0] + 1 and msg[1] == data[1]:
            return msg
        if msg[0] == 0xFF and msg[14] == data[0] and msg[15] == data[1]:
            return msg
    return None


def drain(device):
    try:
        while device.device.read(64, timeout=5):
            pass
    except Exception:
        pass


def start_streaming(device):
    """CAM's handshake."""
    drain(device)
    info = command(device, [0x30, 0x01])
    brightness = info[0x18] if info else 80
    for data in ([0x10, 0x02], [0x70, 0x02, 0x01, 0xB8, 0x0B], [0x74, 0x01],
                 [0x36, 0x04], [0x30, 0x01], [0x36, 0x03],
                 [0x30, 0x02, 0x00, 0x00, 0x00, 0x00, 0x1E],
                 [0x38, 0x01, 0x02]):
        command(device, data)
    for bucket in range(16):
        command(device, [0x32, 0x02, bucket])
    command(device, [0x30, 0x02, 0x01, brightness, 0x00, 0x00, 0x00, 0x1E])
    drain(device)


# Streamed frames ignore the orientation the panel keeps for its own liquid
# screen; mounted as atlas's is, the panel shows them a quarter turn
# clockwise, so they're sent a quarter turn the other way.
TURN = 90


def upload(device, image):
    frame = image.rotate(TURN).convert("RGB").tobytes("raw", "BGR")
    drain(device)
    if command(device, [0x36, 0x01, 0x00, 0x01, 0x09]) is None:
        raise RuntimeError("the screen didn't take the frame's start")
    device.bulk_device.write(
        0x2, bytes(MAGIC + [0x09, 0, 0, 0]) + len(frame).to_bytes(4, "little"))
    for i in range(0, len(frame), URB):
        device.bulk_device.write(0x2, frame[i:i + URB])
    if command(device, [0x36, 0x02], timeout=2000) is None:
        raise RuntimeError("the screen didn't take the frame's end")


def connect():
    for device in find_liquidctl_devices(match="kraken"):
        device.connect()
        return device
    return None


def stock(device):
    """The cooler's own liquid screen, as when nothing drives it."""
    try:
        command(device, [0x38, 0x01, 0x02])
        device.disconnect()
    except Exception:
        pass


def main():
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    device = None
    last, last_at = None, 0.0
    try:
        while True:
            try:
                if device is None:
                    device = connect()
                    if device is None:
                        time.sleep(10)
                        continue
                    start_streaming(device)
                    last = None
                r = readings()
                now = time.monotonic()
                if shown(r) != last or now - last_at > REFRESH:
                    upload(device, render(r))
                    last, last_at = shown(r), now
            # USB gone (unplugged, the VM took it), or a reply that never came
            except Exception as error:
                print(f"kraken-lcd: {error}", file=sys.stderr, flush=True)
                try:
                    if device is not None:
                        device.disconnect()
                except Exception:
                    pass
                device = None
                time.sleep(5)
                continue
            time.sleep(UPDATE)
    finally:
        if device is not None:
            stock(device)


if __name__ == "__main__":
    main()
