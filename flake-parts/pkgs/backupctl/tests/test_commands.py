"""Subcommand behaviour, with restic replaced by a recorder."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path

import pytest

from backupctl import cli, restic
from backupctl.commands import maintain, passthrough, replicate, status, sync_keys
from backupctl.config import Config, parse
from backupctl.errors import UsageError

from .conftest import Recorder

NOW = datetime(2026, 9, 28, 12, 0, tzinfo=UTC)


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


def test_handoff_row_summarises_relay(sample: dict, tmp_path: Path) -> None:
    fake = tmp_path / "handoff"
    fake.write_text(
        "#!/bin/sh\n"
        "cat <<'EOF'\n"
        + json.dumps(
            {
                "relay": "storagebox",
                "host": "h",
                "healthy": False,
                "units": [
                    {
                        "unit_id": "a/x",
                        "state": "in sync",
                        "relay_time": "2026-09-28T09:00:00+00:00",
                    },
                    {
                        "unit_id": "a/y",
                        "state": "push pending",
                        "relay_time": "2026-09-28T11:00:00+00:00",
                    },
                    {"unit_id": "a/z", "state": "never pushed", "relay_time": None},
                ],
                "others": [],
            }
        )
        + "\nEOF\n"
    )
    fake.chmod(0o755)
    sample["handoff"] = str(fake)
    row = status.handoff_row(parse(sample), now=NOW)
    assert row[:3] == ["handoff", "storagebox", "2"]
    assert row[4] == "1.0h"
    assert row[5] == "1 never pushed, 1 push pending"


def test_handoff_row_unavailable(sample: dict) -> None:
    sample["handoff"] = "/nonexistent/handoff"
    row = status.handoff_row(parse(sample), now=NOW)
    assert row[0] == "handoff"
    assert row[5].startswith("unavailable")


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


# --- status rows ---


def test_status_row_reports_restic_errors(config: Config, monkeypatch: pytest.MonkeyPatch) -> None:
    def fail(*_args: object, **_kwargs: object) -> None:
        raise restic.ResticError("alpha", "snapshots", False, 10)

    monkeypatch.setattr("backupctl.restic.run", fail)
    cells, ok = status.row(config, config.repositories["alpha"], replica=False, now=NOW, max_age=26)
    assert cells[-1] == "repository does not exist"
    assert not ok


def test_status_row_fresh_and_stale(config: Config, monkeypatch: pytest.MonkeyPatch) -> None:
    snapshots = '[{"time": "2026-09-28T10:00:00+00:00"}, {"time": "2026-09-27T10:00:00+00:00"}]'
    monkeypatch.setattr("backupctl.restic.run", lambda *_a, **_k: snapshots)
    repo = config.repositories["alpha"]
    cells, ok = status.row(config, repo, replica=False, now=NOW, max_age=26)
    assert (cells[2], cells[4], cells[5], ok) == ("2", "2.0h", "ok", True)
    cells, ok = status.row(config, repo, replica=False, now=NOW, max_age=1)
    assert (cells[5], ok) == ("stale", False)


def test_status_row_empty_repository(config: Config, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("backupctl.restic.run", lambda *_a, **_k: "null")
    cells, ok = status.row(config, config.repositories["beta"], replica=False, now=NOW, max_age=26)
    assert (cells[5], ok) == ("empty", False)


def test_status_row_replica_not_attached(sample: dict, tmp_path: Path) -> None:
    sample["repositories"]["alpha"]["replica"] = str(tmp_path / "unplugged" / "restic" / "alpha")
    config = parse(sample)
    cells, ok = status.row(config, config.repositories["alpha"], replica=True, now=NOW, max_age=26)
    assert (cells[1], cells[5], ok) == ("replica", "not attached", False)


def test_cli_restic_failure_exits_1(
    tmp_path: Path, sample: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    def fail(*_args: object, **_kwargs: object) -> None:
        raise restic.ResticError("alpha", "forget", False, 12)

    config_path = tmp_path / "config.json"
    config_path.write_text(json.dumps(sample))
    monkeypatch.setattr("backupctl.restic.run", fail)
    assert cli.main(["--config", str(config_path), "maintain", "alpha"]) == 1


def test_status_row_replica_not_initialized(sample: dict, tmp_path: Path) -> None:
    sample["repositories"]["alpha"]["replica"] = str(tmp_path / "restic" / "alpha")
    config = parse(sample)
    cells, ok = status.row(config, config.repositories["alpha"], replica=True, now=NOW, max_age=26)
    assert (cells[5], ok) == ("not initialized", False)
