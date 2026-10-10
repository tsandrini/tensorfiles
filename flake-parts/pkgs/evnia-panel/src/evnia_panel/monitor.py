"""Monitor facade shared by the CLI and the panel.

Combines the DDC transport, the menu table and the USB LampArray into typed
operations: read everything, set one item with read-back, pick a picture
mode, drive the strip from the host. Also owns the tiny host-side state
(mode map from the config, last host-set colour).
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path

from evnia_panel import items
from evnia_panel.ddc import Ddc, DdcError, DdcRefused, Reading
from evnia_panel.items import Item
from evnia_panel.lamparray import LampArray, LampArrayError, find_hidraw

MODE_CODE = 0xDC
POWER_CODE = 0xD6

#: Default picture mode map (``DC`` value -> label). Names with ``?`` are
#: unconfirmed; the HM module overrides this file-wise.
DEFAULT_MODES: dict[int, str] = {
    0x00: "Standard",
    0x01: "FPS?",
    0x03: "Movie?",
    0x04: "Game1",
    0x05: "05?",
    0x06: "06?",
    0x07: "07?",
    0x08: "Economy",
    0x0B: "LowBlueMode?",
    0x0E: "EasyRead",
    0x51: "Illustrator?",
}

#: ``DC`` values the monitor accepts in SDR (the HDR ones are rejected there
#: and would only mislead); ``E2`` is excluded on purpose.
MODE_VALUES = frozenset({0x00, 0x01, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x0B, 0x0E, 0x51})

#: ``D6`` power: on, and the "standby" the panel falls into on DPMS.
POWER_ON = 0x01
POWER_OFF = 0x04

#: The OSD's Ambiglow colour names (minus Rainbow) as RGB for host painting.
PALETTE: dict[str, tuple[int, int, int]] = {
    "white": (255, 255, 255),
    "red": (255, 0, 0),
    "rose": (255, 0, 128),
    "magenta": (255, 0, 255),
    "violet": (128, 0, 255),
    "blue": (0, 0, 255),
    "azure": (0, 128, 255),
    "cyan": (0, 255, 255),
    "aqua": (0, 255, 128),
    "green": (0, 255, 0),
    "pear": (128, 255, 0),
    "yellow": (255, 255, 0),
    "orange": (255, 128, 0),
}

AMBIGLOW_MONITOR = "monitor"
AMBIGLOW_OFF = "off"
AMBIGLOW_SOLID = "solid"


class MonitorError(RuntimeError):
    """Umbrella for backend errors, with a user-facing message."""


def parse_edid(edid: bytes) -> dict[str, str]:
    """Pull the human-readable bits out of an EDID block.

    Returns:
        ``manufacturer`` (3-letter PNP id), ``product`` (hex), ``name`` and
        ``serial`` (from the descriptor strings when present), ``week``/``year``.

    Example:
        >>> parse_edid(bytes(128))["manufacturer"]
        '@@@'
    """
    info: dict[str, str] = {}
    if len(edid) < 128:
        return info
    code = (edid[8] << 8) | edid[9]
    info["manufacturer"] = "".join(chr(64 + ((code >> shift) & 0x1F)) for shift in (10, 5, 0))
    info["product"] = f"{edid[11]:02X}{edid[10]:02X}"
    info["week"] = str(edid[16])
    info["year"] = str(1990 + edid[17])
    for offset in (54, 72, 90, 108):
        block = edid[offset : offset + 18]
        if block[:3] != b"\x00\x00\x00":
            continue
        text = block[5:18].decode("ascii", "replace").split("\n")[0].strip()
        if block[3] == 0xFC:
            info["name"] = text
        elif block[3] == 0xFF:
            info["serial"] = text
    return info


def parse_rgb(text: str) -> tuple[int, int, int]:
    """Parse ``rrggbb`` / ``#rrggbb`` or a palette name.

    Example:
        >>> parse_rgb("#ff8800")
        (255, 136, 0)
        >>> parse_rgb("azure")
        (0, 128, 255)
    """
    key = text.strip().lower()
    if key in PALETTE:
        return PALETTE[key]
    hexstr = key.removeprefix("#")
    if len(hexstr) != 6:
        raise ValueError(f"colour must be rrggbb or one of {', '.join(PALETTE)}: {text!r}")
    try:
        value = int(hexstr, 16)
    except ValueError as exc:
        raise ValueError(f"not a hex colour: {text!r}") from exc
    return (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF


def format_rgb(rgb: tuple[int, int, int]) -> str:
    """Format an RGB triple as ``rrggbb``."""
    return "{:02x}{:02x}{:02x}".format(*rgb)


def load_modes(path: Path | None = None) -> dict[int, str]:
    """Load the picture mode map.

    Args:
        path: JSON file ``{"hex": "label", ...}``; defaults to
            ``$XDG_CONFIG_HOME/evnia-panel/modes.json``. A missing file
            yields :data:`DEFAULT_MODES`.

    Raises:
        MonitorError: The file exists but is not a valid map.
    """
    if path is None:
        base = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
        path = base / "evnia-panel" / "modes.json"
    if not path.exists():
        return dict(DEFAULT_MODES)
    try:
        raw = json.loads(path.read_text())
        return {int(k, 16): str(v) for k, v in raw.items()}
    except (OSError, ValueError, AttributeError) as exc:
        raise MonitorError(f"invalid mode map {path}: {exc}") from exc


def _state_path() -> Path:
    base = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
    return base / "evnia-panel" / "ambiglow.json"


@dataclass
class AmbiglowState:
    """What the host last told the strip to do (the LampArray can't be read back)."""

    mode: str = AMBIGLOW_MONITOR
    color: tuple[int, int, int] = (255, 128, 0)

    @classmethod
    def load(cls) -> AmbiglowState:
        """Read the saved state; defaults when absent or corrupt."""
        try:
            raw = json.loads(_state_path().read_text())
            mode = raw.get("mode", AMBIGLOW_MONITOR)
            if mode not in (AMBIGLOW_MONITOR, AMBIGLOW_OFF, AMBIGLOW_SOLID):
                mode = AMBIGLOW_MONITOR
            return cls(mode, parse_rgb(raw.get("color", "ff8000")))
        except (OSError, ValueError, AttributeError):
            return cls()

    def save(self) -> None:
        """Persist the state under ``$XDG_STATE_HOME/evnia-panel/``."""
        path = _state_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps({"mode": self.mode, "color": format_rgb(self.color)}))
        tmp.replace(path)


@dataclass
class State:
    """Everything the panel shows, straight from the monitor.

    Attributes:
        mode: Picture mode (``DC``) value, ``None`` if unanswered.
        values: Item id -> reading (absent when the monitor did not answer).
        ambiglow: Saved host-side strip state.
    """

    mode: int | None = None
    values: dict[str, Reading] = field(default_factory=dict)
    ambiglow: AmbiglowState = field(default_factory=AmbiglowState)

    def value(self, item_id: str) -> int | None:
        """Current value of an item, ``None`` when unanswered."""
        reading = self.values.get(item_id)
        return None if reading is None else reading.value


class Monitor:
    """High-level operations on the Evnia, used by both front-ends."""

    def __init__(
        self, modes: dict[int, str] | None = None, bus: int | None = None, transport: Ddc | None = None
    ) -> None:
        """Create the facade.

        Args:
            modes: Picture mode map; loaded from the config file when ``None``.
            bus: Explicit I²C bus (tests / unusual setups).
            transport: Pre-built transport (tests).
        """
        self.modes = modes if modes is not None else load_modes()
        self.ddc = transport or Ddc(bus=bus)

    # --- identity ------------------------------------------------------------

    def identity(self) -> dict[str, str]:
        """Static facts: EDID strings, the buses in use, the LampArray.

        Never raises; missing pieces are reported as text.
        """
        facts: dict[str, str] = {}
        for connector in sorted(Path("/sys/class/drm").glob("card*-*")):
            try:
                edid = (connector / "edid").read_bytes()
            except OSError:
                continue
            if self.ddc.model.encode() in edid:
                facts.update(parse_edid(edid))
                facts["connector"] = connector.name.split("-", 1)[-1]
                break
        try:
            facts["ddc-bus"] = f"/dev/i2c-{self.ddc.bus}"
        except DdcError as exc:
            facts["ddc-bus"] = str(exc)
        node = find_hidraw()
        if node is None:
            facts["lamparray"] = "not found (USB upstream cable?)"
        else:
            try:
                with LampArray(node) as lamps:
                    attrs = lamps.attributes()
                size = f"{attrs.width_um // 1000} x {attrs.height_um // 1000} mm"
                facts["lamparray"] = f"{node}, {attrs.lamp_count} lamps, {size}"
            except LampArrayError as exc:
                facts["lamparray"] = f"{node}: {exc}"
        return facts

    # --- reading ------------------------------------------------------------

    def _read_item(self, item: Item) -> Reading:
        return self.ddc.get_vcp(item.address) if item.source == items.VCP else self.ddc.get_sub(item.address)

    def read_item(self, item_id: str) -> Reading:
        """Read one item.

        Raises:
            MonitorError: Unknown item or bus failure.
        """
        item = items.BY_ID.get(item_id)
        if item is None:
            raise MonitorError(f"unknown item {item_id!r}")
        try:
            return self._read_item(item)
        except DdcError as exc:
            raise MonitorError(f"{item_id}: {exc}") from exc

    def read_mode(self) -> int | None:
        """Read the picture mode, ``None`` on failure."""
        try:
            return self.ddc.get_vcp(MODE_CODE).value
        except DdcError:
            return None

    def read(self, section: str | None = None) -> State:
        """Read the picture mode and every item (or one section's items).

        Items the monitor does not answer are left out instead of failing
        the whole read; a dead bus raises.

        Raises:
            MonitorError: The monitor is unreachable.
        """
        state = State(ambiglow=AmbiglowState.load())
        try:
            state.mode = self.ddc.get_vcp(MODE_CODE).value
        except DdcError as exc:
            raise MonitorError(str(exc)) from exc
        for item in items.ITEMS:
            if section is not None and item.section != section:
                continue
            try:
                state.values[item.id] = self._read_item(item)
            except DdcError:
                continue
        return state

    # --- writing ----------------------------------------------------------------

    def set_item(self, item_id: str, value: int) -> Reading:
        """Write one item (all its addresses) and return the read-back.

        Raises:
            MonitorError: Unknown item, value outside the allow-list, the
                firmware refused (read-back differs), or bus failure.
        """
        item = items.BY_ID.get(item_id)
        if item is None:
            raise MonitorError(f"unknown item {item_id!r}")
        if value not in item.allowed():
            if not item.writable:
                raise MonitorError(f"{item.label} is read-only over DDC")
            raise MonitorError(f"{item.label}: {value} is not an allowed value")
        try:
            for address in item.addresses:
                if item.source == items.VCP:
                    self.ddc.set_vcp(address, value)
                else:
                    self.ddc.set_sub(address, value)
            read = self._read_item(item)
        except (DdcError, DdcRefused) as exc:
            raise MonitorError(f"{item.label}: {exc}") from exc
        if read.value != value:
            raise MonitorError(f"{item.label}: the monitor kept {item.label_for(read.value)}")
        return read

    def set_mode(self, value: int) -> int:
        """Set the picture mode and return the read-back value.

        Raises:
            MonitorError: Value not accepted in SDR, or bus failure.
        """
        if value not in MODE_VALUES:
            raise MonitorError(f"picture mode {value:02X} is not an SDR mode of this monitor")
        try:
            self.ddc.set_vcp(MODE_CODE, value)
            read = self.ddc.get_vcp(MODE_CODE).value
        except (DdcError, DdcRefused) as exc:
            raise MonitorError(f"picture mode: {exc}") from exc
        if read != value:
            raise MonitorError(f"picture mode: the monitor kept {self.mode_label(read)}")
        return read

    def set_power(self, on: bool) -> int:
        """Power the panel on or into standby (``D6``); returns the read-back."""
        try:
            self.ddc.set_vcp(POWER_CODE, POWER_ON if on else POWER_OFF)
            return self.ddc.get_vcp(POWER_CODE).value
        except (DdcError, DdcRefused) as exc:
            raise MonitorError(f"power: {exc}") from exc

    def mode_value(self, name_or_hex: str) -> int:
        """Resolve a mode label (case-insensitive, ``?`` optional) or hex value.

        Raises:
            ValueError: Nothing matches.
        """
        key = name_or_hex.strip().lower().rstrip("?")
        for value, label in self.modes.items():
            if label.lower().rstrip("?") == key:
                return value
        try:
            return int(key, 16)
        except ValueError:
            raise ValueError(f"unknown picture mode {name_or_hex!r}") from None

    def mode_label(self, value: int | None) -> str:
        """Label for a ``DC`` value; unknown ones show as hex."""
        if value is None:
            return "unknown"
        return self.modes.get(value, f"{value:02X}")

    # --- host-side Ambiglow (USB LampArray) -----------------------------------------

    def ambiglow_monitor(self) -> AmbiglowState:
        """Hand the strip back to the monitor's own Ambiglow logic."""
        try:
            with LampArray() as lamps:
                lamps.control(autonomous=True)
        except LampArrayError as exc:
            raise MonitorError(str(exc)) from exc
        state = AmbiglowState.load()
        state.mode = AMBIGLOW_MONITOR
        state.save()
        return state

    def ambiglow_off(self) -> AmbiglowState:
        """Take host control and switch every lamp off."""
        return self._paint((0, 0, 0), AMBIGLOW_OFF, remember=False)

    def ambiglow_solid(self, rgb: tuple[int, int, int]) -> AmbiglowState:
        """Take host control and paint the whole strip one colour."""
        return self._paint(rgb, AMBIGLOW_SOLID, remember=True)

    def _paint(self, rgb: tuple[int, int, int], mode: str, *, remember: bool) -> AmbiglowState:
        try:
            with LampArray() as lamps:
                lamps.set_all(rgb)
        except LampArrayError as exc:
            raise MonitorError(str(exc)) from exc
        state = AmbiglowState.load()
        state.mode = mode
        if remember:
            state.color = rgb
        state.save()
        return state
