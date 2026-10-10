"""Ambiglow control over the USB HID LampArray interface.

The monitor exposes its 34 Ambiglow LEDs as a HID "Lighting and Illumination"
(usage page 0x59) LampArray device. This module talks to it with raw
``HIDIOCGFEATURE``/``HIDIOCSFEATURE`` ioctls on ``/dev/hidraw*``; no HID
library is needed. Report layouts and sizes were read off the device's
report descriptor:

====  =====================  ===========================================
id    name                   payload (little endian, after the id byte)
====  =====================  ===========================================
1     LampArrayAttributes    u16 count, u32 w, u32 h, u32 d, u32 kind, u32 µs
2     LampAttributesRequest  u16 lamp id
3     LampAttributesResponse u16 id, u32 x y z, u32 latency, u32 purposes,
                             u8 R G B I, u8 programmable, u8 input binding
4     LampMultiUpdate        u8 count, u8 flags, u16 id[8], u8 RGBI[8][4]
5     LampRangeUpdate        u8 flags, u16 start, u16 end, u8 R G B I
6     LampArrayControl       u8 autonomous (1 = monitor logic, 0 = host)
====  =====================  ===========================================
"""

from __future__ import annotations

import fcntl
import os
import struct
from dataclasses import dataclass
from pathlib import Path

VENDOR_ID = 0x0CF2
PRODUCT_ID = 0xB217

#: Flag bit of the range/multi updates meaning "this completes the frame".
UPDATE_COMPLETE = 0x01

_RID_ATTRIBUTES = 1
_RID_LAMP_REQUEST = 2
_RID_LAMP_RESPONSE = 3
_RID_RANGE_UPDATE = 5
_RID_CONTROL = 6

_FMT_ATTRIBUTES = "<BHIIIII"
_FMT_LAMP_REQUEST = "<BH"
_FMT_LAMP_RESPONSE = "<BHIIIIIBBBBBB"
_FMT_RANGE_UPDATE = "<BBHHBBBB"
_FMT_CONTROL = "<BB"

#: Feature report sizes including the id byte, from the report descriptor.
_SIZES = {1: 23, 2: 3, 3: 29, 4: 51, 5: 10, 6: 2}


def _ioc(nr: int, size: int) -> int:
    # _IOC(_IOC_READ | _IOC_WRITE, 'H', nr, size)
    return (3 << 30) | (size << 16) | (ord("H") << 8) | nr


def _hidiocsfeature(size: int) -> int:
    return _ioc(0x06, size)


def _hidiocgfeature(size: int) -> int:
    return _ioc(0x07, size)


class LampArrayError(RuntimeError):
    """The device is missing or an ioctl failed."""


@dataclass(frozen=True)
class Attributes:
    """``LampArrayAttributes`` report."""

    lamp_count: int
    width_um: int
    height_um: int
    depth_um: int
    kind: int
    min_update_interval_us: int


@dataclass(frozen=True)
class Lamp:
    """``LampAttributesResponse`` report for one lamp."""

    lamp_id: int
    x_um: int
    y_um: int
    z_um: int
    update_latency_us: int
    purposes: int
    red_levels: int
    green_levels: int
    blue_levels: int
    intensity_levels: int
    programmable: bool
    input_binding: int


def pack_range_update(start: int, end: int, rgb: tuple[int, int, int], intensity: int = 1) -> bytes:
    """Build a ``LampRangeUpdate`` report.

    Args:
        start: First lamp id.
        end: Last lamp id (inclusive).
        rgb: Colour channels, 0-255 each.
        intensity: Intensity channel; the Evnia only knows ``1``.

    Returns:
        The report bytes with the id byte and ``UPDATE_COMPLETE`` set.

    Example:
        >>> pack_range_update(0, 33, (255, 0, 0)).hex()
        '050100002100ff000001'
    """
    r, g, b = rgb
    if not all(0 <= c <= 255 for c in rgb):
        raise ValueError(f"colour channels out of range: {rgb}")
    return struct.pack(_FMT_RANGE_UPDATE, _RID_RANGE_UPDATE, UPDATE_COMPLETE, start, end, r, g, b, intensity)


def pack_control(autonomous: bool) -> bytes:
    """Build a ``LampArrayControl`` report.

    Args:
        autonomous: ``True`` hands the strip back to the monitor's own
            Ambiglow logic, ``False`` puts the host in charge.

    Returns:
        The report bytes.
    """
    return struct.pack(_FMT_CONTROL, _RID_CONTROL, 1 if autonomous else 0)


def find_hidraw(
    vendor: int = VENDOR_ID, product: int = PRODUCT_ID, sysfs: Path = Path("/sys/class/hidraw")
) -> Path | None:
    """Locate the hidraw node of a USB HID device by vendor/product id.

    Args:
        vendor: USB vendor id.
        product: USB product id.
        sysfs: ``/sys/class/hidraw`` (overridable for tests).

    Returns:
        The ``/dev/hidrawN`` path, or ``None`` when the device is absent.
    """
    needle = f"HID_ID=0003:{vendor:08X}:{product:08X}"
    try:
        entries = sorted(sysfs.iterdir())
    except OSError:
        return None
    for entry in entries:
        try:
            uevent = (entry / "device" / "uevent").read_text()
        except OSError:
            continue
        if needle in uevent:
            return Path("/dev") / entry.name
    return None


class LampArray:
    """Open LampArray device. Use as a context manager."""

    def __init__(self, node: Path | None = None) -> None:
        """Open the device.

        Args:
            node: hidraw node; auto-detected when ``None``.

        Raises:
            LampArrayError: The device is absent or cannot be opened.
        """
        node = node or find_hidraw()
        if node is None:
            raise LampArrayError("Evnia LampArray not found (needs the USB upstream cable)")
        try:
            self._fd = os.open(node, os.O_RDWR)
        except OSError as exc:
            raise LampArrayError(f"cannot open {node}: {exc.strerror}") from exc
        self.node = node

    def __enter__(self) -> LampArray:
        return self

    def __exit__(self, *_exc: object) -> None:
        self.close()

    def close(self) -> None:
        """Close the device node (idempotent)."""
        if self._fd >= 0:
            os.close(self._fd)
            self._fd = -1

    def _set(self, report: bytes) -> None:
        expected = _SIZES[report[0]]
        if len(report) != expected:
            raise LampArrayError(f"report {report[0]} must be {expected} bytes, got {len(report)}")
        try:
            fcntl.ioctl(self._fd, _hidiocsfeature(len(report)), report)
        except OSError as exc:
            raise LampArrayError(f"HIDIOCSFEATURE({report[0]}) failed: {exc.strerror}") from exc

    def _get(self, report_id: int) -> bytes:
        buf = bytearray(_SIZES[report_id])
        buf[0] = report_id
        try:
            fcntl.ioctl(self._fd, _hidiocgfeature(len(buf)), buf)
        except OSError as exc:
            raise LampArrayError(f"HIDIOCGFEATURE({report_id}) failed: {exc.strerror}") from exc
        return bytes(buf)

    def attributes(self) -> Attributes:
        """Read the array-wide attributes (lamp count, bounding box, ...)."""
        fields = struct.unpack(_FMT_ATTRIBUTES, self._get(_RID_ATTRIBUTES))
        return Attributes(*fields[1:])

    def lamp(self, lamp_id: int) -> Lamp:
        """Read one lamp's attributes (position, channel depth, ...)."""
        self._set(struct.pack(_FMT_LAMP_REQUEST, _RID_LAMP_REQUEST, lamp_id))
        fields = struct.unpack(_FMT_LAMP_RESPONSE, self._get(_RID_LAMP_RESPONSE))
        return Lamp(*fields[1:11], bool(fields[11]), fields[12])

    def control(self, autonomous: bool) -> None:
        """Switch between the monitor's own Ambiglow logic and host control."""
        self._set(pack_control(autonomous))

    def set_range(self, start: int, end: int, rgb: tuple[int, int, int]) -> None:
        """Set lamps ``start..end`` (inclusive) to one colour."""
        self._set(pack_range_update(start, end, rgb))

    def set_all(self, rgb: tuple[int, int, int]) -> None:
        """Take host control and paint every lamp in one colour.

        On any failure after control was taken, control is handed back to
        the monitor so the strip is never left half-painted in host mode.
        """
        count = self.attributes().lamp_count
        self.control(autonomous=False)
        try:
            self.set_range(0, count - 1, rgb)
        except LampArrayError:
            self.control(autonomous=True)
            raise
