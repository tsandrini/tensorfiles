"""Subcommand behaviour, with restic replaced by a recorder."""

from __future__ import annotations

import argparse
from datetime import UTC, datetime
from pathlib import Path

import pytest

from backupctl import cli
from backupctl.commands import maintain, passthrough, replicate, status, sync_keys
from backupctl.config import Config, parse
from backupctl.errors import UsageError

from .conftest import Recorder


def ns(**kwargs: object) -> argparse.Namespace:
    return argparse.Namespace(**kwargs)


# --- status ---


def test_newest_handles_nanoseconds() -> None:
    snapshots = [
        {"time": "2026-09-28T13:46:35.123456789+02:00"},
        {"time": "2026-09-28T19:00:00+02:00"},
    ]
    assert status.newest(snapshots) == datetime(2026, 9, 28, 17, 0, tzinfo=UTC)


@pytest.mark.parametrize("snapshots", [[], None])
def test_newest_empty(snapshots: list | None) -> None:
    assert status.newest(snapshots) is None


# --- maintain ---


def test_maintain_refuses_append_only(config: Config, recorder: Recorder) -> None:
    with pytest.raises(UsageError, match="append-only access to beta"):
        maintain.run(config, ns(repos=[], read_data_subset=None))
    assert recorder.calls == []


def test_maintain_refuses_without_retention(sample: dict, recorder: Recorder) -> None:
    sample["retention"] = []
    with pytest.raises(UsageError, match="retention"):
        maintain.run(parse(sample), ns(repos=["alpha"], read_data_subset=None))
    assert recorder.calls == []


def test_maintain_skips_unavailable_replica(config: Config, recorder: Recorder) -> None:
    assert maintain.run(config, ns(repos=["alpha"], read_data_subset="1%")) == 0
    assert recorder.subcommands() == [
        ("rclone:restic/alpha", "forget"),
        ("rclone:restic/alpha", "check"),
    ]
    assert recorder.calls[1][-2:] == ["--read-data-subset", "1%"]
    assert "--keep-daily=14" in recorder.calls[0]


def test_maintain_includes_ready_replica(sample: dict, recorder: Recorder, tmp_path: Path) -> None:
    (tmp_path / "config").write_text("")
    sample["repositories"]["alpha"]["replica"] = str(tmp_path)
    assert maintain.run(parse(sample), ns(repos=["alpha"], read_data_subset=None)) == 0
    assert [repo for repo, _ in recorder.subcommands()] == [
        "rclone:restic/alpha",
        "rclone:restic/alpha",
        str(tmp_path),
        str(tmp_path),
    ]


# --- replicate ---


def test_replicate_initializes_then_copies(
    sample: dict, recorder: Recorder, tmp_path: Path
) -> None:
    sample["replicaRoot"] = str(tmp_path)
    sample["repositories"]["alpha"]["replica"] = str(tmp_path / "alpha")
    assert replicate.run(parse(sample), ns(repos=[])) == 0
    assert recorder.subcommands() == [
        (str(tmp_path / "alpha"), "init"),
        (str(tmp_path / "alpha"), "copy"),
    ]
    assert "--copy-chunker-params" in recorder.calls[0]
    assert "--from-repo" in recorder.calls[1]


def test_replicate_skips_init_when_ready(sample: dict, recorder: Recorder, tmp_path: Path) -> None:
    (tmp_path / "alpha").mkdir()
    (tmp_path / "alpha" / "config").write_text("")
    sample["replicaRoot"] = str(tmp_path)
    sample["repositories"]["alpha"]["replica"] = str(tmp_path / "alpha")
    replicate.run(parse(sample), ns(repos=["alpha"]))
    assert [sub for _, sub in recorder.subcommands()] == ["copy"]


def test_replicate_needs_replica_root(sample: dict, recorder: Recorder) -> None:
    sample["replicaRoot"] = None
    with pytest.raises(UsageError, match="replicaRoot"):
        replicate.run(parse(sample), ns(repos=[]))


# --- sync-keys ---


def test_sync_keys_diff() -> None:
    assert sync_keys.diff("a\nb\n", "a\nb\n") == []
    changes = sync_keys.diff("a\nold\n", "a\nnew\n")
    assert "-old\n" in changes
    assert "+new\n" in changes


def test_sync_keys_unavailable(sample: dict) -> None:
    sample["authorizedKeysFile"] = None
    with pytest.raises(UsageError, match="not available"):
        sync_keys.run(parse(sample), ns(apply=False))


# --- restic passthrough / cli ---


def test_passthrough_parsing() -> None:
    parser = cli.build_parser()
    args = parser.parse_args(["restic", "--replica", "alpha", "snapshots", "--json"])
    assert (args.repo, args.replica, args.args) == ("alpha", True, ["snapshots", "--json"])
    args = parser.parse_args(["restic", "alpha", "--", "ls", "latest"])
    assert passthrough.restic_args(args.args) == ["ls", "latest"]


def test_cli_reports_config_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert cli.main(["--config", str(tmp_path / "missing.json"), "status"]) == 2
    assert "cannot read" in capsys.readouterr().err


def test_cli_requires_command() -> None:
    with pytest.raises(SystemExit):
        cli.main([])
