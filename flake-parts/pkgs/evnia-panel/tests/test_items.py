"""The menu table is the allow-list; keep it consistent."""

import pytest

from evnia_panel import ddc, items


def test_ids_unique_and_sections_known() -> None:
    ids = [i.id for i in items.ITEMS]
    assert len(ids) == len(set(ids))
    sections = {s for s, _ in items.SECTIONS}
    assert all(i.section in sections for i in items.ITEMS)


def test_no_forbidden_vcp_and_allowed_sets() -> None:
    for item in items.ITEMS:
        if item.source == items.VCP:
            assert not (set(item.addresses) & ddc.FORBIDDEN), item.id
        if item.kind == items.RANGE:
            assert item.span and item.allowed() == frozenset(range(item.span[0], item.span[1] + 1))
        elif item.kind == items.INFO:
            assert not item.writable and item.allowed() == frozenset()
        elif item.writable:
            assert item.allowed() == frozenset(item.values)
    assert items.BY_ID["adaptive-sync"].allowed() == frozenset()
    assert items.BY_ID["kvm"].allowed() == frozenset()


def test_parse_labels_numbers_toggles() -> None:
    light = items.BY_ID["light-mode"]
    assert light.parse("color wave") == 4
    assert light.parse("Static Mode") == 7
    assert light.parse("3") == 3
    mute = items.BY_ID["mute"]
    assert mute.parse("on") == 0x01
    assert mute.parse("off") == 0x02
    gamma = items.BY_ID["gamma"]
    assert gamma.parse("2.4") == 0x8C
    assert gamma.parse("0x78") == 0x78
    with pytest.raises(ValueError):
        light.parse("disco")


def test_label_for() -> None:
    item = items.BY_ID["crosshair"]
    assert item.label_for(2) == "Smart Crosshair"
    assert item.label_for(9) == "09?"
    assert item.label_for(None) == "unknown"
    assert items.BY_ID["volume"].label_for(42) == "42"


def test_sections_have_icons_and_info_is_read_only() -> None:
    assert set(items.ICONS) == {s for s, _ in items.SECTIONS}
    for item in items.in_section("info"):
        assert item.kind == items.INFO and not item.writable
    assert items.BY_ID["firmware"].label_for(0x0100) == "1.00"
    assert items.BY_ID["mccs-version"].label_for(0x0202) == "2.2"
    assert items.BY_ID["oled-hours"].label_for(18) == "18 h"
