"""Config parsing."""

from __future__ import annotations

from pathlib import Path

import pytest

from handoff.config import DEFAULT_ALWAYS_EXCLUDE, load, parse
from handoff.errors import ConfigError, UsageError

MINIMAL = {
    "relay": {
        "storagebox": {
            "path": "/home/handoff",
            "backend": {"type": "sftp", "host": "box", "user": "u1", "port": 23},
        }
    },
    "workspace": {"root": "~/ProjectBundle"},
}


def test_minimal() -> None:
    config = parse(MINIMAL)
    relay = config.relay(None)
    assert relay.name == "storagebox"
    assert relay.backend == {"type": "sftp", "host": "box", "user": "u1", "port": "23"}
    assert relay.crypt is None
    assert relay.transfers == 16
    assert config.workspace.root == Path("~/ProjectBundle").expanduser()
    assert config.workspace.depth == 2
    assert config.defaults.always_exclude == DEFAULT_ALWAYS_EXCLUDE
    assert config.defaults.max_mb == 2000.0


def test_crypt_local_relay_and_overrides() -> None:
    data = {
        **MINIMAL,
        "relay": {
            "default": "usb",
            "usb": {
                "path": "/mnt/usb",
                "backend": {"type": "local", "nounc": True},
                "crypt": {"password_file": "~/pw", "salt_file": "~/salt"},
                "transfers": 4,
                "history": False,
            },
            **MINIMAL["relay"],
        },
        "defaults": {"keep_ignored": [".env"], "max_mb": 10, "always_exclude": ["x"]},
        "repo": {"a/b": {"keep_ignored": ["cfg.yaml"], "always_exclude": ["data"], "max_mb": 0}},
    }
    config = parse(data)
    usb = config.relay(None)
    assert usb.backend == {"type": "local", "nounc": "true"}
    assert usb.crypt is not None
    assert usb.crypt.password_file == Path("~/pw").expanduser()
    assert usb.crypt.salt_file == Path("~/salt").expanduser()
    assert usb.transfers == 4
    assert not usb.history
    rules = config.rules_for("a/b")
    assert rules.keep_ignored == (".env", "cfg.yaml")
    assert rules.always_exclude == ("x", "data")
    assert rules.max_mb == 0
    assert config.rules_for("other").max_mb == 10


@pytest.mark.parametrize(
    ("patch", "match"),
    [
        ({"relay": {}}, "no relays"),
        ({"relay": {"r": {"path": "relative", "backend": {"type": "local"}}}}, "absolute path"),
        ({"relay": {"r": {"path": "/x"}}}, "missing `\\[backend\\]`"),
        ({"relay": {"r": {"path": "/x", "backend": {}}}}, "backend.type"),
        (
            {"relay": {"r": {"path": "/x", "backend": {"type": "local"}, "crypt": {}}}},
            "password_file",
        ),
        (
            {"relay": {"default": "nope", "r": {"path": "/x", "backend": {"type": "local"}}}},
            "unknown relay",
        ),
        ({"workspace": {}}, "missing `root`"),
        ({"workspace": {"root": "/x", "depth": 0}}, "positive integer"),
        ({"defaults": {"keep_ignored": "x"}}, "list of strings"),
    ],
)
def test_errors(patch: dict, match: str) -> None:
    with pytest.raises(ConfigError, match=match):
        parse({**MINIMAL, **patch})


def test_workspace_selection() -> None:
    config = parse(
        {**MINIMAL, "workspace": {"root": "/x", "include": ["a/*"], "exclude": ["a/skip"]}}
    )
    assert config.workspace.selects("a/keep")
    assert not config.workspace.selects("a/skip")
    assert not config.workspace.selects("b/keep")
    assert parse(MINIMAL).workspace.selects("anything/at-all")


def test_unknown_relay_on_cli() -> None:
    with pytest.raises(UsageError, match="unknown relay"):
        parse(MINIMAL).relay("nope")


def test_load_toml(tmp_path: Path) -> None:
    path = tmp_path / "config.toml"
    path.write_text(
        '[relay.r]\npath = "/r"\nbackend = { type = "local" }\n[workspace]\nroot = "/ws"\n'
    )
    assert load(path).workspace.root == Path("/ws")
    path.write_text("not = [toml")
    with pytest.raises(ConfigError, match="not valid TOML"):
        load(path)
    with pytest.raises(ConfigError, match="cannot read"):
        load(tmp_path / "missing.toml")
