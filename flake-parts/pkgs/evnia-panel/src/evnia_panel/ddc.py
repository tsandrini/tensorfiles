"""Raw DDC/CI over the monitor's I²C bus.

Both the standard MCCS VCP codes and Philips' vendor sub-features are
spoken here. The sub-features (``E2A0xx`` in the capability string) need an
*extended* VCP packet that carries the sub-feature address, which no
off-the-shelf tool sends, so this module talks I²C directly instead of
wrapping ``ddcutil``:

======  ============================  ======================================
op      payload (after ``51 len``)    reply payload
======  ============================  ======================================
get     ``01 CC``                     ``02 rc CC type MH ML SH SL``
set     ``03 CC SH SL``               none
sub get ``01 E2 A0 xx``               ``02 rc E2 00 MH ML SH SL``
sub set ``03 E2 A0 xx 00 VV``         none
======  ============================  ======================================

Packets are framed as ``51 (0x80|len) payload chk`` with ``chk`` the XOR over
``6E`` and the frame; replies are ``6E (0x80|len) payload chk`` with the XOR
taken over ``50`` and the frame. The monitor needs ~20 ms between a request
and reading its reply; a bad checksum or a NAK (the monitor is busy, e.g.
re-syncing the link) is retried with a growing gap.

This module is transport only: it refuses the factory-reset codes outright
and leaves every other allow-list decision to :mod:`evnia_panel.items`.
"""

from __future__ import annotations

import errno
import fcntl
import os
import threading
import time
from dataclasses import dataclass
from pathlib import Path

#: Model string in the EDID, used to find the display.
MODEL = "32M2N8900P"

I2C_SLAVE = 0x0703
DDC_ADDRESS = 0x37
_HOST = 0x51
_HOST_REPLY = 0x50
_MONITOR = 0x6E

OP_GET = 0x01
OP_REPLY = 0x02
OP_SET = 0x03
SUB_CODE = 0xE2
SUB_PAGE = 0xA0

#: Never written, whatever any table says: factory resets and the raw selector.
FORBIDDEN = frozenset({0x04, 0x05, 0x08, SUB_CODE})

#: Gap between request and reply read; 20 ms was 100 % reliable, 15 ms not.
DEFAULT_GAP = 0.025
_RETRY_GAPS = (0.04, 0.08, 0.2, 0.5, 1.0)


class DdcError(RuntimeError):
    """The bus or the monitor did not cooperate."""


class DdcRefused(ValueError):
    """A write was refused before touching the bus."""


@dataclass(frozen=True)
class Reading:
    """One value as reported by the monitor."""

    value: int
    maximum: int


def _xor(data: bytes) -> int:
    chk = 0
    for byte in data:
        chk ^= byte
    return chk


def frame(payload: bytes) -> bytes:
    """Frame a host->monitor payload with length byte and checksum.

    Example:
        >>> frame(bytes([0x01, 0x10])).hex()
        '51820110ac'
    """
    body = bytes([_HOST, 0x80 | len(payload)]) + payload
    return body + bytes([_xor(bytes([_MONITOR]) + body)])


def parse_reply(raw: bytes) -> bytes:
    """Validate a monitor->host frame and return its payload.

    Raises:
        DdcError: Bad length, bad checksum, or an all-zero (not ready) reply.

    Example:
        >>> parse_reply(bytes.fromhex("6e 88 02 00 10 00 00 64 00 5a 9a")).hex()
        '020010000064005a'
    """
    if len(raw) < 3 or raw[0] != _MONITOR:
        raise DdcError(f"no DDC reply ({raw[:2].hex()})")
    length = raw[1] & 0x7F
    if len(raw) < length + 3:
        raise DdcError("short DDC reply")
    body = raw[: length + 2]
    if _xor(bytes([_HOST_REPLY]) + body) != raw[length + 2]:
        raise DdcError("DDC reply checksum mismatch")
    return body[2:]


def parse_vcp_reply(payload: bytes, code: int) -> Reading:
    """Decode a ``02`` VCP reply payload for ``code``.

    Raises:
        DdcError: Unexpected opcode/code or the monitor flagged the code
            as unsupported.
    """
    if len(payload) < 8 or payload[0] != OP_REPLY:
        raise DdcError(f"unexpected reply {payload.hex()}")
    if payload[1] != 0:
        raise DdcError(f"VCP {code:02X} unsupported (rc={payload[1]})")
    if payload[2] != code:
        raise DdcError(f"reply for VCP {payload[2]:02X}, asked for {code:02X}")
    return Reading((payload[6] << 8) | payload[7], (payload[4] << 8) | payload[5])


def find_bus_sysfs(model: str = MODEL, drm: Path = Path("/sys/class/drm")) -> int | None:
    """Find the I²C bus carrying DDC/CI for a connected monitor via sysfs.

    For DisplayPort the AUX channel bus is an ``i2c-N`` child of the DRM
    connector whose EDID carries ``model``; for HDMI/DVI the connector's
    ``ddc`` link points at the bus.

    Returns:
        The bus number, or ``None`` when the monitor is not found.
    """
    needle = model.encode()
    for connector in sorted(drm.glob("card*-*")):
        try:
            if needle not in (connector / "edid").read_bytes():
                continue
        except OSError:
            continue
        for child in connector.iterdir():
            if child.name.startswith("i2c-"):
                return int(child.name[4:])
        ddc = connector / "ddc"
        if ddc.is_symlink() and ddc.resolve().name.startswith("i2c-"):
            return int(ddc.resolve().name[4:])
    return None


class Ddc:
    """Serialised DDC/CI access to one monitor.

    The bus is resolved and opened lazily; all traffic goes through one lock
    because DDC/CI is a single slow bus with per-request state.
    """

    def __init__(self, model: str = MODEL, bus: int | None = None, gap: float = DEFAULT_GAP) -> None:
        """Create the handle.

        Args:
            model: Model string used to locate the display in sysfs.
            bus: Explicit I²C bus number, skipping detection.
            gap: Seconds to wait between a request and reading the reply.
        """
        self.model = model
        self._bus = bus
        self._gap = gap
        self._fd = -1
        self._lock = threading.Lock()

    @property
    def bus(self) -> int:
        """I²C bus number of the monitor.

        Raises:
            DdcError: The monitor is not connected / not detectable.
        """
        if self._bus is None:
            bus = find_bus_sysfs(self.model)
            if bus is None:
                raise DdcError(f"monitor {self.model} not found (DDC/CI needs the video cable)")
            self._bus = bus
        return self._bus

    def _open(self) -> int:
        if self._fd < 0:
            node = f"/dev/i2c-{self.bus}"
            try:
                self._fd = os.open(node, os.O_RDWR)
                fcntl.ioctl(self._fd, I2C_SLAVE, DDC_ADDRESS)
            except OSError as exc:
                raise DdcError(f"cannot open {node}: {exc.strerror}") from exc
        return self._fd

    def close(self) -> None:
        """Close the bus (idempotent)."""
        if self._fd >= 0:
            os.close(self._fd)
            self._fd = -1

    def _txn(self, payload: bytes, reply: bool) -> bytes | None:
        with self._lock:
            fd = self._open()
            last: Exception | None = None
            for attempt, retry_gap in enumerate((self._gap, *_RETRY_GAPS)):
                try:
                    os.write(fd, frame(payload))
                    if not reply:
                        time.sleep(self._gap)
                        return None
                    time.sleep(retry_gap)
                    raw = os.read(fd, 16)
                    time.sleep(0.005)
                    return parse_reply(raw)
                except OSError as exc:
                    # NOTE: EIO/EREMOTEIO = monitor NAKs while busy (link
                    # re-sync, standby); back off and retry
                    last = exc
                    if exc.errno not in (errno.EIO, errno.EREMOTEIO, errno.ETIMEDOUT, errno.EAGAIN):
                        break
                    time.sleep(_RETRY_GAPS[min(attempt, len(_RETRY_GAPS) - 1)])
                except DdcError as exc:
                    last = exc
            raise DdcError(f"DDC transaction failed: {last}")

    # --- standard VCP ----------------------------------------------------------

    def get_vcp(self, code: int) -> Reading:
        """Read one VCP code."""
        payload = self._txn(bytes([OP_GET, code]), reply=True)
        assert payload is not None
        return parse_vcp_reply(payload, code)

    def set_vcp(self, code: int, value: int) -> None:
        """Write one VCP code (no read-back; callers verify).

        Raises:
            DdcRefused: Factory-reset codes or the raw sub-feature selector.
        """
        if code in FORBIDDEN:
            raise DdcRefused(f"VCP {code:02X} is never written by evnia-panel")
        self._txn(bytes([OP_SET, code, (value >> 8) & 0xFF, value & 0xFF]), reply=False)

    # --- Philips sub-features --------------------------------------------------

    def get_sub(self, addr: int) -> Reading:
        """Read sub-feature ``E2 A0 addr``."""
        payload = self._txn(bytes([OP_GET, SUB_CODE, SUB_PAGE, addr]), reply=True)
        assert payload is not None
        return parse_vcp_reply(payload, SUB_CODE)

    def set_sub(self, addr: int, value: int) -> None:
        """Write sub-feature ``E2 A0 addr`` (no read-back; callers verify)."""
        self._txn(bytes([OP_SET, SUB_CODE, SUB_PAGE, addr, (value >> 8) & 0xFF, value & 0xFF]), reply=False)
