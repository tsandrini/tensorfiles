"""Fixtures: two hosts (separate workspaces and state) sharing a local relay.

Every test runs twice, against a plaintext relay and an encrypted one.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

import pytest

from handoff.config import Config, Crypt, Relay, Rules, Workspace
from handoff.engine import Engine
from handoff.state import StateStore
from handoff.store import Store


@pytest.fixture(autouse=True)
def _git_identity(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GIT_AUTHOR_NAME", "t")
    monkeypatch.setenv("GIT_AUTHOR_EMAIL", "t@example.invalid")
    monkeypatch.setenv("GIT_COMMITTER_NAME", "t")
    monkeypatch.setenv("GIT_COMMITTER_EMAIL", "t@example.invalid")
    monkeypatch.setenv("GIT_CONFIG_GLOBAL", os.devnull)
    monkeypatch.setenv("GIT_CONFIG_SYSTEM", os.devnull)


def git(repo: Path, *args: str) -> str:
    """Run git in a repository and return stdout."""
    return subprocess.run(
        ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
    ).stdout


def write(repo: Path, rel: str, text: str) -> None:
    """Write a file below a repository, creating parents."""
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def make_repo(root: Path, unit_id: str, files: dict[str, str] | None = None) -> Path:
    """Create a committed repository at `<root>/<unit_id>`."""
    repo = root / unit_id
    repo.mkdir(parents=True)
    git(repo, "init", "-q", "-b", "main")
    for rel, text in (files or {"README.md": "hello\n"}).items():
        write(repo, rel, text)
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "init")
    return repo


@pytest.fixture(params=["plain", "crypt"])
def relay(tmp_path: Path, request: pytest.FixtureRequest) -> Relay:
    """A local-directory relay, plaintext or encrypted."""
    relay_dir = tmp_path / "relay"
    crypt = None
    if request.param == "crypt":
        password = tmp_path / "crypt-password"
        password.write_text("correct horse battery staple\n")
        crypt = Crypt(password_file=password)
    return Relay(name="local", path=str(relay_dir), backend={"type": "local"}, crypt=crypt)


@dataclass
class Host:
    """One simulated machine."""

    name: str
    config: Config
    tmp: Path

    def engine(self) -> Engine:
        relay_cfg = self.config.relay(None)
        scratch = Path(tempfile.mkdtemp(prefix="scratch-", dir=self.tmp))
        return Engine(
            self.config,
            Store(relay_cfg, scratch),
            StateStore(self.config.state_dir, relay_cfg.name),
        )

    def path(self, unit_id: str) -> Path:
        return self.config.workspace.root / unit_id

    def _store(self) -> Store:
        return Store(self.config.relay(None), Path(tempfile.mkdtemp(dir=self.tmp)))

    def relay_files(self, sub: str) -> list[str]:
        """Decrypted relative paths of the regular files below `sub` on the relay."""
        store = self._store()
        proc = subprocess.run(
            ["rclone", "lsf", "-R", "--files-only", store.remote(sub)],
            capture_output=True,
            text=True,
            env=store.env(),
        )
        return sorted(proc.stdout.split()) if proc.returncode == 0 else []

    def relay_read(self, sub: str) -> str:
        """Decrypted content of one file on the relay."""
        store = self._store()
        return subprocess.run(
            ["rclone", "cat", store.remote(sub)],
            capture_output=True,
            text=True,
            check=True,
            env=store.env(),
        ).stdout


def make_host(tmp_path: Path, relay: Relay, name: str, **rules: object) -> Host:
    base = tmp_path / name
    (base / "ws").mkdir(parents=True)
    config = Config(
        relays={relay.name: relay},
        default_relay=relay.name,
        workspace=Workspace(
            root=base / "ws", depth=2, include=("work/*", "other/*"), exclude=("*/excluded-*",)
        ),
        defaults=Rules(keep_ignored=(".env",), max_mb=None, **rules),  # type: ignore[arg-type]
        host=name,
        state_dir=base / "state",
    )
    return Host(name, config, base)


@pytest.fixture
def alpha(tmp_path: Path, relay: Relay) -> Host:
    return make_host(tmp_path, relay, "alpha")


@pytest.fixture
def beta(tmp_path: Path, relay: Relay) -> Host:
    return make_host(tmp_path, relay, "beta")
