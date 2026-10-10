"""Report packing and device discovery for the LampArray layer."""

from pathlib import Path

import pytest

from evnia_panel import lamparray


def test_pack_range_update_layout() -> None:
    report = lamparray.pack_range_update(0, 33, (255, 136, 0))
    assert report.hex() == "050100002100ff880001"
    assert len(report) == lamparray._SIZES[5]


def test_pack_control() -> None:
    assert lamparray.pack_control(True) == b"\x06\x01"
    assert lamparray.pack_control(False) == b"\x06\x00"


def test_pack_range_update_rejects_bad_channel() -> None:
    with pytest.raises(ValueError):
        lamparray.pack_range_update(0, 33, (256, 0, 0))


def test_find_hidraw(tmp_path: Path) -> None:
    for name, hid_id in (("hidraw3", "0003:0000046D:0000C52B"), ("hidraw9", "0003:00000CF2:0000B217")):
        (tmp_path / name / "device").mkdir(parents=True)
        (tmp_path / name / "device" / "uevent").write_text(f"DRIVER=hid-generic\nHID_ID={hid_id}\n")
    assert lamparray.find_hidraw(sysfs=tmp_path) == Path("/dev/hidraw9")
    assert lamparray.find_hidraw(vendor=0x1234, sysfs=tmp_path) is None
