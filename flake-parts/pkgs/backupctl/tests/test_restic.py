"""restic argv construction and path probing."""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import pytest

from backupctl import restic
from backupctl.config import Config
from backupctl.errors import UsageError


def test_repo_args_include_options(config: Config) -> None:
    assert restic.repo_args(config.repositories["alpha"]) == [
        "--repo",
        "rclone:restic/alpha",
        "--password-file",
        "/run/alpha-pw",
        "-o",
        "rclone.program=ssh -i key restic-storagebox",
    ]


def test_repo_args_replica_is_local(config: Config) -> None:
    assert restic.repo_args(config.repositories["alpha"], replica=True) == [
        "--repo",
        "/replicas/alpha",
        "--password-file",
        "/run/alpha-pw",
    ]


def test_repo_args_replica_missing(config: Config) -> None:
    with pytest.raises(UsageError, match="no replica"):
        restic.repo_args(config.repositories["beta"], replica=True)


def test_from_repo_args(config: Config) -> None:
    assert restic.from_repo_args(config.repositories["alpha"]) == [
        "--from-repo",
        "rclone:restic/alpha",
        "--from-password-file",
        "/run/alpha-pw",
        "-o",
        "rclone.program=ssh -i key restic-storagebox",
    ]


def test_command_prefixes_binary(config: Config) -> None:
    argv = restic.command(config, config.repositories["beta"], "snapshots", "--json")
    assert argv[0] == "/bin/restic"
    assert argv[-2:] == ["snapshots", "--json"]


def test_available(tmp_path: Path) -> None:
    assert restic.available(tmp_path)
    assert not restic.available(tmp_path / "missing")


def test_listable(tmp_path: Path) -> None:
    assert restic.listable(tmp_path)
    assert not restic.listable(tmp_path / "missing")


def test_replica_ready(config: Config, tmp_path: Path) -> None:
    repo = config.repositories["alpha"]
    assert not restic.replica_ready(repo)
    (tmp_path / "config").write_text("")
    assert restic.replica_ready(replace(repo, replica=str(tmp_path)))
    assert not restic.replica_ready(config.repositories["beta"])


def test_subcommand_skips_options() -> None:
    assert restic.subcommand(("--no-lock", "snapshots", "--json")) == "snapshots"
    assert restic.subcommand(()) == "restic"


def test_error_detail_prefers_json_exit_error() -> None:
    stderr = (
        'rclone: NOTICE: config not found\n{"message_type":"exit_error","code":10,'
        '"message":"Fatal: repository does not exist: unable to open config\\nIs there"}\n'
    )
    assert restic.error_detail(stderr) == "Fatal: repository does not exist: unable to open config"


def test_error_detail_falls_back_to_last_line() -> None:
    assert restic.error_detail("first\n\nFatal: wrong password\n") == "Fatal: wrong password"
    assert restic.error_detail("") is None


def test_restic_error_message() -> None:
    err = restic.ResticError("alpha", "snapshots", False, 10)
    assert err.reason == "repository does not exist"
    assert str(err) == "`restic snapshots` on alpha: repository does not exist"
    assert restic.ResticError("alpha", "copy", True, 42).reason == "exit code 42"
    assert "(replica)" in str(restic.ResticError("alpha", "copy", True, 1))
