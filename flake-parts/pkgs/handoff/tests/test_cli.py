"""Command line smoke tests."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

import handoff
from handoff import cli

from .conftest import make_repo


@pytest.fixture
def config_file(tmp_path: Path) -> Path:
    (tmp_path / "ws").mkdir()
    path = tmp_path / "config.toml"
    path.write_text(
        f'state_dir = "{tmp_path / "state"}"\nhost = "testhost"\n'
        f'[relay.local]\npath = "{tmp_path / "relay"}"\nbackend = {{ type = "local" }}\n'
        f'[workspace]\nroot = "{tmp_path / "ws"}"\n'
    )
    return path


def test_status_json_on_empty_relay(config_file: Path, capsys: pytest.CaptureFixture) -> None:
    assert cli.main(["--config", str(config_file), "status", "--json"]) == 0
    data = json.loads(capsys.readouterr().out)
    assert data == {
        "relay": "local",
        "host": "testhost",
        "healthy": True,
        "units": [],
    }


def test_retired_claude_table_still_loads(config_file: Path) -> None:
    with config_file.open("a") as f:
        f.write('[claude]\nroot = "~/.claude"\nexclude = []\nconflicts_dir = "handoff-conflicts"\n')
    # NOTE: own process, pytest's log handlers would swallow the CLI's stderr format
    env = {**os.environ, "PYTHONPATH": str(Path(handoff.__file__).parents[1])}
    proc = subprocess.run(
        [sys.executable, "-m", "handoff", "--config", str(config_file), "status", "--json"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert proc.returncode == 0
    assert proc.stderr == (
        "handoff: ignoring [claude]: Claude Code state syncs through ccdash now; remove the table\n"
    )
    assert "claude" not in json.loads(proc.stdout)


@pytest.mark.parametrize("command", ["push", "pull", "status", "verify"])
def test_retired_claude_unit_is_refused(
    config_file: Path, tmp_path: Path, capsys: pytest.CaptureFixture, command: str
) -> None:
    make_repo(tmp_path / "ws", "b/r")
    assert cli.main(["--config", str(config_file), command, "b/r", "claude"]) == 2
    err = capsys.readouterr().err
    assert "Claude Code state is no longer handled by handoff because ccdash syncs it" in err
    assert "matches no unit" not in err
    assert not (tmp_path / "relay").exists()


def test_push_pull_status_round_trip(
    config_file: Path, tmp_path: Path, capsys: pytest.CaptureFixture
) -> None:
    make_repo(tmp_path / "ws", "b/r")
    assert cli.main(["--config", str(config_file), "status"]) == 1
    assert "never pushed" in capsys.readouterr().out
    assert cli.main(["--config", str(config_file), "push"]) == 0
    assert "pushed" in capsys.readouterr().out
    assert cli.main(["--config", str(config_file), "status", "b/"]) == 0
    assert "in sync" in capsys.readouterr().out
    assert cli.main(["--config", str(config_file), "pull", "-n"]) == 0


def test_config_and_usage_errors(config_file: Path, capsys: pytest.CaptureFixture) -> None:
    assert cli.main(["--config", "/nonexistent.toml", "status"]) == 2
    assert "cannot read" in capsys.readouterr().err
    assert cli.main(["--config", str(config_file), "push", "nope/"]) == 2
    assert "matches no unit" in capsys.readouterr().err
    assert cli.main(["--config", str(config_file), "pull", "--take-relay", "--keep-local"]) == 2
