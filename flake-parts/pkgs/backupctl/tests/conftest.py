"""Shared fixtures."""

from __future__ import annotations

import copy
from typing import Any

import pytest

from backupctl.config import Config, parse

SAMPLE: dict[str, Any] = {
    "restic": "/bin/restic",
    "ssh": "/bin/ssh",
    "sftp": "/bin/sftp",
    "sshAlias": "restic-storagebox",
    "authorizedKeysFile": "/keys",
    "replicaRoot": "/replicas",
    "retention": ["--keep-daily=14"],
    "checkReadDataSubset": "5%",
    "browseDirectory": "Backups",
    "repositories": {
        "alpha": {
            "repository": "rclone:restic/alpha",
            "passwordFile": "/run/alpha-pw",
            "options": {"rclone.program": "ssh -i key restic-storagebox"},
            "replica": "/replicas/alpha",
        },
        "beta": {
            "repository": "rclone:restic/beta",
            "passwordFile": "/run/beta-pw",
            "appendOnly": True,
        },
    },
}


@pytest.fixture
def sample() -> dict[str, Any]:
    """A fresh, mutable copy of the sample config document."""
    return copy.deepcopy(SAMPLE)


@pytest.fixture
def config(sample: dict[str, Any]) -> Config:
    """The parsed sample config."""
    return parse(sample)


class Recorder:
    """Stands in for `restic.run`, recording every argv instead of running it."""

    def __init__(self) -> None:
        self.calls: list[list[str]] = []

    def __call__(self, argv: list[str], *, capture: bool = False) -> None:
        self.calls.append(argv)

    def subcommands(self) -> list[tuple[str, str]]:
        """(repository argument, restic subcommand) of every recorded call."""
        return [
            (argv[argv.index("--repo") + 1], argv[_subcommand_index(argv)]) for argv in self.calls
        ]


def _subcommand_index(argv: list[str]) -> int:
    i = 1
    while argv[i].startswith("-"):
        i += 2  # every global option used here takes a value
    return i


@pytest.fixture
def recorder(monkeypatch: pytest.MonkeyPatch) -> Recorder:
    """Patch `restic.run` and return the recorder."""
    rec = Recorder()
    monkeypatch.setattr("backupctl.restic.run", rec)
    return rec
