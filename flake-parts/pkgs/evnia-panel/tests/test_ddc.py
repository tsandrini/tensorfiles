"""Pure parts of the DDC transport: framing, parsing, sysfs bus lookup, refusals."""

from pathlib import Path

import pytest

from evnia_panel import ddc


def test_frame_checksum() -> None:
    assert ddc.frame(bytes([0x01, 0x10])).hex() == "51820110ac"
    assert ddc.frame(bytes([0x01, 0xE2, 0xA0, 0x1A])).hex() == "518401e2a01ae2"


def test_parse_reply_and_vcp() -> None:
    raw = bytes.fromhex("6e 88 02 00 10 00 00 64 00 5a 9a 00 00 00")
    payload = ddc.parse_reply(raw)
    assert ddc.parse_vcp_reply(payload, 0x10) == ddc.Reading(value=0x5A, maximum=100)
    sub = ddc.parse_reply(bytes.fromhex("6e 88 02 00 e2 00 00 0d 00 02 59"))
    assert ddc.parse_vcp_reply(sub, 0xE2) == ddc.Reading(2, 13)


def test_parse_reply_rejects_bad_checksum_and_unsupported() -> None:
    with pytest.raises(ddc.DdcError):
        ddc.parse_reply(bytes.fromhex("6e 88 02 00 10 00 00 64 00 5a 9b"))
    with pytest.raises(ddc.DdcError):
        ddc.parse_vcp_reply(bytes.fromhex("02 01 a0 00 00 04 00 04"), 0xA0)
    with pytest.raises(ddc.DdcError):
        ddc.parse_reply(b"\x00\x00\x00")


def test_set_vcp_refuses_forbidden_without_bus() -> None:
    d = ddc.Ddc(bus=99)
    for code in (0x04, 0x05, 0x08, 0xE2):
        with pytest.raises(ddc.DdcRefused):
            d.set_vcp(code, 1)


def test_find_bus_sysfs_prefers_aux_child(tmp_path: Path) -> None:
    dp = tmp_path / "card1-DP-1"
    dp.mkdir()
    (dp / "edid").write_bytes(b"\x00\xff" + b"32M2N8900P" + b"\x00")
    (dp / "i2c-8").mkdir()
    (dp / "ddc").symlink_to(tmp_path / "i2c-4")
    hdmi = tmp_path / "card1-HDMI-A-1"
    hdmi.mkdir()
    (hdmi / "edid").write_bytes(b"P2417H")
    assert ddc.find_bus_sysfs("32M2N8900P", drm=tmp_path) == 8
    assert ddc.find_bus_sysfs("P2417H", drm=tmp_path) is None
