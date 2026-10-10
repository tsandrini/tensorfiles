"""Facade: reads, writes with read-back, refusals, mode map, state file."""

import json
from pathlib import Path

import pytest

from evnia_panel import ddc, items, monitor


class FakeDdc:
    """In-memory monitor: VCP and sub-feature tables, optional stubborn addresses."""

    def __init__(self) -> None:
        self.vcp = {
            0xDC: 0x00,
            0x10: 60,
            0x12: 50,
            0x72: 0x78,
            0x14: 0x05,
            0x87: 5,
            0x54: 1,
            0x60: 0x0F,
            0x62: 50,
            0x8D: 2,
            0xD6: 1,
        }
        self.vcp.update({0x16: 100, 0x18: 100, 0x1A: 100, 0x86: 0x25, 0xDA: 0})
        self.sub = {i.address: 0 for i in items.ITEMS if i.source == items.SUB}
        self.sub.update({a: 0 for i in items.ITEMS if i.source == items.SUB for a in i.addresses})
        self.sub[0x4E] = 17
        self.stubborn = {0x54}  # VCP codes the firmware ignores writes to
        self.writes: list[tuple[str, int, int]] = []

    def get_vcp(self, code: int) -> ddc.Reading:
        if code not in self.vcp:
            raise ddc.DdcError("unsupported")
        return ddc.Reading(self.vcp[code], 100)

    def set_vcp(self, code: int, value: int) -> None:
        if code in ddc.FORBIDDEN:
            raise ddc.DdcRefused("forbidden")
        self.writes.append(("vcp", code, value))
        if code not in self.stubborn:
            self.vcp[code] = value

    def get_sub(self, addr: int) -> ddc.Reading:
        return ddc.Reading(self.sub[addr], 7)

    def set_sub(self, addr: int, value: int) -> None:
        self.writes.append(("sub", addr, value))
        self.sub[addr] = value


@pytest.fixture
def mon(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> monitor.Monitor:
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    return monitor.Monitor(modes={0x00: "Standard", 0x08: "Economy"}, transport=FakeDdc())


def test_read_all_and_section(mon: monitor.Monitor) -> None:
    state = mon.read()
    assert state.mode == 0
    assert state.value("brightness") == 60
    assert state.value("oled-hours") == 17
    assert set(mon.read("oled").values) == {i.id for i in items.in_section("oled")}


def test_set_item_writes_every_address_and_reads_back(mon: monitor.Monitor) -> None:
    read = mon.set_item("shadowboost", 2)
    assert read.value == 2
    fake: FakeDdc = mon.ddc  # type: ignore[assignment]
    assert [w for w in fake.writes if w[0] == "sub"] == [("sub", 0x44, 2), ("sub", 0x45, 2), ("sub", 0x46, 2)]


def test_set_item_refusals(mon: monitor.Monitor) -> None:
    with pytest.raises(monitor.MonitorError, match="read-only"):
        mon.set_item("adaptive-sync", 1)
    with pytest.raises(monitor.MonitorError, match="not an allowed value"):
        mon.set_item("brightness", 101)
    with pytest.raises(monitor.MonitorError, match="kept"):
        mon.set_item("pixel-orbiting", 2)
    with pytest.raises(monitor.MonitorError, match="unknown item"):
        mon.set_item("nope", 1)
    fake: FakeDdc = mon.ddc  # type: ignore[assignment]
    assert not [w for w in fake.writes if w[1] == 0x40]


def test_set_mode(mon: monitor.Monitor) -> None:
    assert mon.set_mode(0x08) == 0x08
    with pytest.raises(monitor.MonitorError):
        mon.set_mode(0xE2)
    with pytest.raises(monitor.MonitorError):
        mon.set_mode(0x20)


def test_parse_rgb() -> None:
    assert monitor.parse_rgb("#ff8800") == (255, 136, 0)
    assert monitor.parse_rgb("Azure") == (0, 128, 255)
    with pytest.raises(ValueError):
        monitor.parse_rgb("fff")


def test_load_modes_file_and_default(tmp_path: Path) -> None:
    assert monitor.load_modes(tmp_path / "missing.json") == monitor.DEFAULT_MODES
    path = tmp_path / "modes.json"
    path.write_text(json.dumps({"00": "Standard", "51": "Illustrator"}))
    assert monitor.load_modes(path) == {0x00: "Standard", 0x51: "Illustrator"}
    path.write_text("[1, 2]")
    with pytest.raises(monitor.MonitorError):
        monitor.load_modes(path)


def test_mode_value_lookup(mon: monitor.Monitor) -> None:
    assert mon.mode_value("economy") == 8
    assert mon.mode_value("0e") == 0x0E
    assert mon.mode_label(0x0E) == "0E"
    with pytest.raises(ValueError):
        mon.mode_value("nope")


def test_ambiglow_state_roundtrip(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    assert monitor.AmbiglowState.load() == monitor.AmbiglowState()
    monitor.AmbiglowState(monitor.AMBIGLOW_SOLID, (1, 2, 3)).save()
    assert monitor.AmbiglowState.load() == monitor.AmbiglowState("solid", (1, 2, 3))
    (tmp_path / "evnia-panel" / "ambiglow.json").write_text("{garbage")
    assert monitor.AmbiglowState.load() == monitor.AmbiglowState()


def test_parse_edid_descriptors() -> None:
    edid = bytearray(128)
    edid[8], edid[9] = 0x41, 0x0C  # "PHL"
    edid[10], edid[11] = 0x34, 0x12
    edid[16], edid[17] = 12, 35
    edid[54:72] = b"\x00\x00\x00\xfc\x00" + b"32M2N8900P\n  "
    edid[72:90] = b"\x00\x00\x00\xff\x00" + b"AU02611004077"
    info = monitor.parse_edid(bytes(edid))
    assert info["manufacturer"] == "PHL"
    assert info["product"] == "1234"
    assert info["name"] == "32M2N8900P"
    assert info["serial"] == "AU02611004077"
    assert info["year"] == "2025" and info["week"] == "12"
    assert monitor.parse_edid(b"short") == {}
