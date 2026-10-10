"""The monitor's menu as data.

Every row the panel shows and every value the CLI accepts comes from this
table, which mirrors the OSD sections of the 32M2N8900P. The table *is* the
allow-list: an item is writable only if it says so, and only with the values
it lists (measured with the real monitor, see
``desktop-build/research/evnia-e2-subfeatures-2026-10-10.md``).

Sources are either a standard VCP code or a Philips sub-feature address;
some items are mirrored in several addresses (per-input copies), which are
all written and the first one read.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass, field

VCP = "vcp"
SUB = "sub"

RANGE = "range"
ENUM = "enum"
TOGGLE = "toggle"
INFO = "info"

#: Section ids and titles in the OSD's order (plus Info).
SECTIONS: tuple[tuple[str, str], ...] = (
    ("smartimage", "SmartImage"),
    ("gamemode", "GameMode"),
    ("ambiglow", "Ambiglow"),
    ("input", "Input"),
    ("audio", "Audio"),
    ("system", "System"),
    ("oled", "OLED care"),
    ("info", "Info"),
)

#: Symbolic icon per section (Adwaita icon theme).
ICONS: dict[str, str] = {
    "smartimage": "image-x-generic-symbolic",
    "gamemode": "input-gaming-symbolic",
    "ambiglow": "weather-clear-symbolic",
    "input": "video-display-symbolic",
    "audio": "audio-speakers-symbolic",
    "system": "preferences-system-symbolic",
    "oled": "preferences-desktop-screensaver-symbolic",
    "info": "dialog-information-symbolic",
}


@dataclass(frozen=True)
class Item:
    """One menu item.

    Attributes:
        id: Stable identifier used by the CLI and the state file.
        section: One of :data:`SECTIONS`.
        label: Row title.
        kind: ``range`` (``span``), ``enum`` (``values``), ``toggle``
            (``values`` = {off: label, on: label}, in that order) or ``info``
            (read-only number).
        source: ``vcp`` or ``sub``.
        addresses: VCP code(s) or sub-feature address(es); the first is read,
            all are written.
        values: Enum/toggle value -> label.
        span: Inclusive range for ``range`` items.
        writable: ``False`` for items the firmware refuses over DDC.
        note: Shown under the row.
        fmt: Formatter for ``info`` values (e.g. a BCD version).
    """

    id: str
    section: str
    label: str
    kind: str
    source: str
    addresses: tuple[int, ...]
    values: dict[int, str] = field(default_factory=dict)
    span: tuple[int, int] | None = None
    writable: bool = True
    note: str = ""
    fmt: Callable[[int], str] | None = None

    @property
    def address(self) -> int:
        """The address that is read."""
        return self.addresses[0]

    def allowed(self) -> frozenset[int]:
        """Values a write may use (empty when not writable)."""
        if not self.writable:
            return frozenset()
        if self.kind == RANGE and self.span:
            return frozenset(range(self.span[0], self.span[1] + 1))
        return frozenset(self.values)

    def label_for(self, value: int | None) -> str:
        """Human label for a value (hex for unknown enum values)."""
        if value is None:
            return "unknown"
        if self.fmt is not None:
            return self.fmt(value)
        if self.kind in (ENUM, TOGGLE):
            return self.values.get(value, f"{value:02X}?")
        return str(value)

    def parse(self, text: str) -> int:
        """Turn CLI text (label, on/off, number, hex) into a value.

        Raises:
            ValueError: Nothing matches.
        """
        key = text.strip().lower()
        for value, label in self.values.items():
            if label.lower() == key or label.lower().rstrip("?") == key:
                return value
        if self.kind == TOGGLE and key in ("on", "off", "1", "0", "true", "false"):
            off, on = self.values
            return on if key in ("on", "1", "true") else off
        try:
            return int(key, 0) if key.startswith("0x") else int(key)
        except ValueError:
            pass
        try:
            return int(key, 16)
        except ValueError:
            raise ValueError(f"{self.id}: unknown value {text!r}") from None


_LEVELS_0_4 = {0: "Off", 1: "1", 2: "2", 3: "3", 4: "4"}
_OFF_ON = {0: "Off", 1: "On"}


def _version(value: int) -> str:
    return f"{value >> 8}.{value & 0xFF:02d}"


def _hours(value: int) -> str:
    return f"{value} h"


ITEMS: tuple[Item, ...] = (
    # --- SmartImage -------------------------------------------------------------
    # picture mode (VCP DC) is handled by the mode map, see monitor.py
    Item(
        "brightness",
        "smartimage",
        "Brightness",
        RANGE,
        VCP,
        (0x10,),
        span=(0, 100),
        note="panel light output; each SmartImage mode keeps its own value",
    ),
    Item(
        "contrast",
        "smartimage",
        "Contrast",
        RANGE,
        VCP,
        (0x12,),
        span=(0, 100),
        note="white-to-black ratio; the mode keeps its own value",
    ),
    Item(
        "gamma",
        "smartimage",
        "Gamma",
        ENUM,
        VCP,
        (0x72,),
        {0x50: "1.8", 0x64: "2.0", 0x78: "2.2", 0x8C: "2.4", 0xA0: "2.6"},
        note="tone curve; 2.2 is the sRGB standard, higher = darker mid-tones",
    ),
    Item(
        "color-temp",
        "smartimage",
        "Colour temperature",
        ENUM,
        VCP,
        (0x14,),
        {
            0x02: "Native",
            0x04: "5000K",
            0x05: "6500K",
            0x06: "7500K",
            0x07: "8200K",
            0x08: "9300K",
            0x0A: "User 1",
            0x0B: "User 2",
            0x0D: "User 3",
        },
        note="white point; Native = the panel's own, User = the RGB gains below",
    ),
    Item(
        "sharpness",
        "smartimage",
        "Sharpness",
        RANGE,
        VCP,
        (0x87,),
        span=(0, 10),
        note="edge enhancement, 0-10",
    ),
    Item(
        "red",
        "smartimage",
        "Red",
        RANGE,
        VCP,
        (0x16,),
        span=(0, 100),
        note="RGB gain, used with the User colour temperatures; follows the mode",
    ),
    Item("green", "smartimage", "Green", RANGE, VCP, (0x18,), span=(0, 100), note="RGB gain"),
    Item("blue", "smartimage", "Blue", RANGE, VCP, (0x1A,), span=(0, 100), note="RGB gain"),
    # --- GameMode ---------------------------------------------------------------
    Item(
        "adaptive-sync",
        "gamemode",
        "Adaptive Sync",
        TOGGLE,
        SUB,
        (0x40, 0x41),
        _OFF_ON,
        writable=False,
        note="variable refresh rate (FreeSync / G-Sync compatible); read-only over DDC, the firmware refuses",
    ),
    Item(
        "crosshair",
        "gamemode",
        "Crosshair",
        ENUM,
        SUB,
        (0x04,),
        {0: "Off", 1: "On", 2: "Smart Crosshair"},
        note="an aiming reticle drawn by the monitor; Smart Crosshair adapts its colour to the background",
    ),
    Item(
        "shadowboost",
        "gamemode",
        "Stark ShadowBoost",
        ENUM,
        SUB,
        (0x44, 0x45, 0x46),
        {0: "Off", 1: "Level 1", 2: "Level 2", 3: "Level 3"},
        note="lifts dark areas so shadows stay readable; higher = stronger",
    ),
    Item(
        "sniper-size",
        "gamemode",
        "Smart Sniper size",
        ENUM,
        SUB,
        (0x06,),
        {0: "Off", 1: "1.0", 2: "1.5", 3: "2.0"},
        note="magnifier window for the screen centre; changing it re-syncs the DisplayPort link "
        "(black for ~1 s)",
    ),
    Item(
        "sniper-position",
        "gamemode",
        "Smart Sniper position",
        ENUM,
        SUB,
        (0x05,),
        {0: "0?", 1: "1?", 2: "Central"},
        note="where the magnifier window sits; only active while Smart Sniper is on",
    ),
    # --- Ambiglow (the monitor's own effects; host-side colours live in monitor.py)
    Item(
        "ambiglow-enable",
        "ambiglow",
        "Ambiglow",
        TOGGLE,
        SUB,
        (0x08,),
        _OFF_ON,
        note="the LED strip on the back; off = dark",
    ),
    Item(
        "light-mode",
        "ambiglow",
        "Light mode",
        ENUM,
        SUB,
        (0x19,),
        {
            1: "Follow Video",
            2: "Follow Audio",
            3: "Color Shift",
            4: "Color Wave",
            5: "Color Breathing",
            6: "Starry Night",
            7: "Static Mode",
        },
        note="Follow Video/Audio react to the screen or sound; Shift/Wave/Breathing animate; "
        "Static holds one colour",
    ),
    Item(
        "light-color",
        "ambiglow",
        "Colour",
        ENUM,
        SUB,
        (0x1A,),
        {
            0: "Rainbow",
            1: "White",
            2: "Red",
            3: "Rose",
            4: "Magenta",
            5: "Violet",
            6: "Blue",
            7: "Azure",
            8: "Cyan",
            9: "Aqua",
            10: "Green",
            11: "Pear",
            12: "Yellow",
            13: "Orange",
        },
        note="Rainbow = multi-colour; the firmware may refuse it in Follow Video",
    ),
    Item(
        "light-position",
        "ambiglow",
        "Light position",
        ENUM,
        SUB,
        (0x1B,),
        {0: "All zones", 1: "3-sides", 2: "Central"},
        note="which lamps take part: all, the three sides, or the centre; not available in Follow Video",
    ),
    Item(
        "light-brightness",
        "ambiglow",
        "Brightness",
        ENUM,
        SUB,
        (0x1C,),
        {0: "Bright", 1: "Brighter", 2: "Brightest"},
        note="LED intensity",
    ),
    Item(
        "light-speed",
        "ambiglow",
        "Speed",
        ENUM,
        SUB,
        (0x1D,),
        {0: "Low", 1: "Normal", 2: "High"},
        note="animation speed of the moving effects; not available in Follow Video",
    ),
    # --- Input --------------------------------------------------------------------
    Item(
        "input",
        "input",
        "Input",
        ENUM,
        VCP,
        (0x60,),
        {
            0x0F: "DisplayPort",
            0x11: "HDMI 1",
            0x12: "HDMI 2",
            0x15: "15? (USB-C?)",
            0x21: "21? (USB-C?)",
            0x22: "22? (USB-C?)",
            0x2F: "2F? (USB-C?)",
            0x35: "35? (USB-C?)",
        },
        note="active video input; switching away from DisplayPort loses this panel's connection",
    ),
    # --- Audio --------------------------------------------------------------------
    Item("volume", "audio", "Volume", RANGE, VCP, (0x62,), span=(0, 100), note="built-in speakers"),
    Item("mute", "audio", "Mute", TOGGLE, VCP, (0x8D,), {0x02: "Off", 0x01: "On"}, note="built-in speakers"),
    # --- System -------------------------------------------------------------------
    Item(
        "osd-horizontal",
        "system",
        "OSD horizontal",
        RANGE,
        SUB,
        (0x0E,),
        span=(0, 100),
        note="where the monitor's own menu appears, 0-100",
    ),
    Item("osd-vertical", "system", "OSD vertical", RANGE, SUB, (0x0F,), span=(0, 100), note="0-100"),
    Item(
        "osd-transparency",
        "system",
        "OSD transparency",
        ENUM,
        SUB,
        (0x10,),
        _LEVELS_0_4,
        note="see-through level of the monitor's menu",
    ),
    Item(
        "osd-timeout",
        "system",
        "OSD time out",
        ENUM,
        SUB,
        (0x11,),
        {0: "5 s", 1: "10 s", 2: "20 s", 3: "30 s", 4: "60 s"},
        note="how long the monitor's menu stays open without input",
    ),
    Item(
        "smart-size",
        "system",
        "Smart Size",
        ENUM,
        VCP,
        (0x86,),
        {
            0x25: '32"W',
            0x01: "01?",
            0x0A: "0A?",
            0x12: "12?",
            0x13: "13?",
            0x14: "14?",
            0x15: "15?",
            0x16: "16?",
            0x17: "17?",
            0x18: "18?",
            0x19: "19?",
            0x1A: "1A?",
            0x1B: "1B?",
            0x23: "23?",
        },
        note="emulates a smaller panel (letterboxed); only the native 32-inch wide value is labelled so far",
    ),
    Item(
        "usb-standby",
        "system",
        "USB standby mode",
        TOGGLE,
        SUB,
        (0x13, 0x14),
        _OFF_ON,
        note="keep the USB hub (and the Ambiglow controller) powered while the panel is in standby",
    ),
    Item(
        "kvm",
        "system",
        "KVM",
        ENUM,
        SUB,
        (0x34,),
        {2: "Auto", 3: "USB C?", 4: "USB UP?"},
        writable=False,
        note="which upstream cable the USB hub follows; read-only: switching it would drop the "
        "Ambiglow USB link",
    ),
    Item(
        "overscan",
        "system",
        "Over Scan",
        ENUM,
        VCP,
        (0xDA,),
        {0x00: "Normal", 0x02: "Overscan"},
        note="crops the picture edges (TV-style)",
    ),
    # --- OLED care (Setup -> OLED Panel Care) ------------------------------------------
    Item(
        "screen-saver",
        "oled",
        "Screen saver",
        ENUM,
        SUB,
        (0x35,),
        {0: "Off", 2: "Slow", 3: "Fast"},
        note="dims the panel after inactivity to protect the OLED; Slow/Fast = how soon",
    ),
    Item(
        "pixel-orbiting",
        "oled",
        "Pixel orbiting",
        ENUM,
        VCP,
        (0x54,),
        {0: "Off", 1: "Slow", 2: "Normal", 3: "Fast"},
        note="shifts the whole image by a few pixels now and then against burn-in; the firmware "
        "refuses changes over DDC",
    ),
    Item(
        "auto-pixel-refresh",
        "oled",
        "Auto pixel refresh",
        TOGGLE,
        SUB,
        (0x61,),
        _OFF_ON,
        note="runs the compensation cycle by itself when the panel goes to standby after ~4 h of use",
    ),
    Item(
        "unibright",
        "oled",
        "UniBright",
        TOGGLE,
        SUB,
        (0x47,),
        _OFF_ON,
        note="uniformity compensation across the panel",
    ),
    Item(
        "logo-protection",
        "oled",
        "Multi logo protection",
        ENUM,
        SUB,
        (0x48,),
        _LEVELS_0_4,
        note="detects static logos and dims them; higher = more aggressive",
    ),
    Item(
        "boundary-dimmer",
        "oled",
        "Boundary dimmer",
        ENUM,
        SUB,
        (0x49,),
        _LEVELS_0_4,
        note="dims static edges such as window borders; higher = more",
    ),
    Item(
        "taskbar-dimmer",
        "oled",
        "Taskbar dimmer",
        ENUM,
        SUB,
        (0x4A,),
        _LEVELS_0_4,
        note="dims a static bar at the bottom or top; higher = more",
    ),
    Item(
        "thermal-protection",
        "oled",
        "Thermal protection",
        TOGGLE,
        SUB,
        (0x4B,),
        _OFF_ON,
        note="lowers brightness when the panel runs hot",
    ),
    # --- Info (read-only) ---------------------------------------------------------------
    Item(
        "oled-hours",
        "info",
        "Working time",
        INFO,
        SUB,
        (0x4E,),
        writable=False,
        note="hours the OLED panel has been on (OSD: OLED Information)",
        fmt=_hours,
    ),
    Item(
        "hours-since-refresh",
        "info",
        "Time after pixel refresh",
        INFO,
        SUB,
        (0x51,),
        writable=False,
        note="hours since the last compensation cycle",
        fmt=_hours,
    ),
    Item(
        "refresh-count",
        "info",
        "Pixel refresh count",
        INFO,
        SUB,
        (0x54,),
        writable=False,
        note="compensation cycles run so far",
    ),
    Item(
        "sensor-a",
        "info",
        "Sensor A",
        INFO,
        SUB,
        (0x4F,),
        writable=False,
        note="rises with use and falls in standby: most likely a panel temperature in degrees C",
    ),
    Item(
        "sensor-b",
        "info",
        "Sensor B",
        INFO,
        SUB,
        (0x53,),
        writable=False,
        note="second temperature-like sensor",
    ),
    Item(
        "firmware",
        "info",
        "Firmware version",
        INFO,
        VCP,
        (0xC9,),
        writable=False,
        note="VCP C9",
        fmt=_version,
    ),
    Item(
        "mccs-version",
        "info",
        "MCCS version",
        INFO,
        VCP,
        (0xDF,),
        writable=False,
        note="DDC/CI command set the monitor implements",
        fmt=lambda v: f"{v >> 8}.{v & 0xFF}",
    ),
)

BY_ID: dict[str, Item] = {item.id: item for item in ITEMS}


def in_section(section: str) -> list[Item]:
    """Items of one section, in table order."""
    return [item for item in ITEMS if item.section == section]
