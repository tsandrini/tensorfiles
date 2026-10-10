"""CLI wiring against the in-memory monitor."""

import pytest

from evnia_panel import cli, ddc, monitor
from tests.test_monitor import FakeDdc


@pytest.fixture
def fake(monkeypatch: pytest.MonkeyPatch, tmp_path) -> FakeDdc:
    backend = FakeDdc()
    monkeypatch.setattr(ddc, "Ddc", lambda **_k: backend)
    monkeypatch.setattr(monitor, "Ddc", lambda **_k: backend)
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path))
    return backend


def test_mode_and_get(fake: FakeDdc, capsys: pytest.CaptureFixture[str]) -> None:
    assert cli.main(["mode", "economy"]) == 0
    assert fake.vcp[0xDC] == 0x08
    assert cli.main(["get"]) == 0
    out = capsys.readouterr().out
    assert "Economy (08)" in out and "[OLED care]" in out and "adaptive-sync" in out


def test_set_by_label_and_number(fake: FakeDdc) -> None:
    assert cli.main(["set", "light-mode", "color wave"]) == 0
    assert fake.sub[0x19] == 4
    assert cli.main(["set", "crosshair", "2"]) == 0
    assert fake.sub[0x04] == 2
    assert cli.main(["set", "mute", "on"]) == 0
    assert fake.vcp[0x8D] == 0x01
    assert cli.main(["set", "brightness", "42"]) == 0
    assert fake.vcp[0x10] == 42


def test_refusals_exit_2(fake: FakeDdc, capsys: pytest.CaptureFixture[str]) -> None:
    assert cli.main(["set", "adaptive-sync", "off"]) == 2
    assert "read-only" in capsys.readouterr().err
    assert cli.main(["set", "brightness", "200"]) == 2
    assert cli.main(["set", "pixel-orbiting", "fast"]) == 2
    assert cli.main(["set", "bogus", "1"]) == 2


def test_items_and_json(fake: FakeDdc, capsys: pytest.CaptureFixture[str]) -> None:
    assert cli.main(["items"]) == 0
    assert "light-mode" in capsys.readouterr().out
    assert cli.main(["get", "--json", "--section", "audio"]) == 0
    assert '"volume"' in capsys.readouterr().out


def test_power(fake: FakeDdc, capsys: pytest.CaptureFixture[str]) -> None:
    assert cli.main(["power", "on"]) == 0
    assert "power = on" in capsys.readouterr().out
