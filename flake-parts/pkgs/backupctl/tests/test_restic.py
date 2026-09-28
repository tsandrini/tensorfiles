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


def test_replica_ready(config: Config, tmp_path: Path) -> None:
    repo = config.repositories["alpha"]
    assert not restic.replica_ready(repo)
    (tmp_path / "config").write_text("")
    assert restic.replica_ready(replace(repo, replica=str(tmp_path)))
    assert not restic.replica_ready(config.repositories["beta"])
