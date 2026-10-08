"""Loading and validation of the backupctl JSON config."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from backupctl.errors import ConfigError, UsageError

DEFAULT_CONFIG_PATH = Path("/etc/backupctl/config.json")
CONFIG_ENV = "BACKUPCTL_CONFIG"


@dataclass(frozen=True)
class Repository:
    """One restic repository together with its optional local replica.

    Attributes:
        name: Repository name, by convention the backed-up host.
        repository: restic repository string, e.g. `rclone:restic/<name>`.
        password_file: File holding the repository password.
        options: restic extended options (`-o key=value`) needed to reach it.
        replica: Path of the local replica repository, `None` if there is none.
        append_only: Whether this host only has append-only access, which
            rules out `forget`/`prune`.
    """

    name: str
    repository: str
    password_file: str
    options: dict[str, str] = field(default_factory=dict)
    replica: str | None = None
    append_only: bool = False


@dataclass(frozen=True)
class Config:
    """Parsed backupctl config.

    Attributes:
        restic: Path of the restic binary.
        ssh: Path of the ssh binary.
        sftp: Path of the sftp binary.
        ssh_alias: ssh_config host alias of the Storage Box.
        repositories: Configured repositories keyed by name.
        replica_root: Directory holding the replicas, `None` if disabled.
        retention: `restic forget` policy arguments used by `maintain`.
        check_read_data_subset: `restic check --read-data-subset` value.
        browse_directory: Mount root for `browse`, relative to `$HOME`.
        authorized_keys_file: Rendered Storage Box `authorized_keys`, `None`
            if `sync-keys` is not available on this host.
        handoff: Path of the `handoff` binary whose relay state `status`
            reports as one more row, `None` to leave it out.
    """

    restic: str
    ssh: str
    sftp: str
    ssh_alias: str
    repositories: dict[str, Repository]
    replica_root: str | None = None
    retention: list[str] = field(default_factory=list)
    check_read_data_subset: str = "5%"
    browse_directory: str = "Backups"
    authorized_keys_file: str | None = None
    handoff: str | None = None

    def select(self, names: list[str], *, require_replica: bool = False) -> list[Repository]:
        """Resolve repository names given on the command line.

        Args:
            names: Requested names, all configured repositories when empty.
            require_replica: Only accept (and default to) repositories that
                have a replica.

        Returns:
            The selected repositories in the requested (or config) order.

        Raises:
            UsageError: A name is unknown, lacks a required replica, or
                nothing is left to act on.
        """
        pool = {
            name: repo
            for name, repo in self.repositories.items()
            if not require_replica or repo.replica is not None
        }
        if not names:
            if not pool:
                raise UsageError("no repositories to act on")
            return list(pool.values())

        selected = []
        for name in names:
            if name not in self.repositories:
                known = ", ".join(self.repositories) or "none"
                raise UsageError(f"unknown repository {name!r} (configured: {known})")
            if name not in pool:
                raise UsageError(f"repository {name!r} has no replica configured")
            selected.append(pool[name])
        return selected


def resolve_path(cli_path: str | None) -> Path:
    """Pick the config file: `--config`, then `$BACKUPCTL_CONFIG`, then the default.

    Args:
        cli_path: Value of `--config`, if given.

    Returns:
        Path of the config file to load.
    """
    if cli_path:
        return Path(cli_path)
    if env_path := os.environ.get(CONFIG_ENV):
        return Path(env_path)
    return DEFAULT_CONFIG_PATH


def load(path: Path) -> Config:
    """Read and parse a config file.

    Args:
        path: JSON config file.

    Returns:
        The parsed config.

    Raises:
        ConfigError: The file cannot be read or is not valid.
    """
    try:
        data = json.loads(path.read_text())
    except OSError as err:
        raise ConfigError(f"cannot read {path}: {err.strerror}") from err
    except json.JSONDecodeError as err:
        raise ConfigError(f"{path} is not valid JSON: {err}") from err
    return parse(data)


def _require(data: dict[str, Any], key: str, where: str) -> Any:
    if key not in data or data[key] is None:
        raise ConfigError(f"missing `{key}` in {where}")
    return data[key]


def parse(data: Any) -> Config:
    """Build a `Config` from decoded JSON.

    Args:
        data: Decoded JSON document.

    Returns:
        The parsed config.

    Raises:
        ConfigError: A required key is missing or has the wrong shape.
    """
    if not isinstance(data, dict):
        raise ConfigError("the config has to be a JSON object")

    raw_repos = _require(data, "repositories", "the config")
    if not isinstance(raw_repos, dict):
        raise ConfigError("`repositories` has to be an object keyed by name")

    repositories = {}
    for name, raw in raw_repos.items():
        where = f"repositories.{name}"
        if not isinstance(raw, dict):
            raise ConfigError(f"{where} has to be an object")
        repositories[name] = Repository(
            name=name,
            repository=_require(raw, "repository", where),
            password_file=_require(raw, "passwordFile", where),
            options=dict(raw.get("options") or {}),
            replica=raw.get("replica"),
            append_only=bool(raw.get("appendOnly", False)),
        )

    return Config(
        restic=_require(data, "restic", "the config"),
        ssh=_require(data, "ssh", "the config"),
        sftp=_require(data, "sftp", "the config"),
        ssh_alias=_require(data, "sshAlias", "the config"),
        repositories=repositories,
        replica_root=data.get("replicaRoot"),
        retention=list(data.get("retention") or []),
        check_read_data_subset=data.get("checkReadDataSubset") or "5%",
        browse_directory=data.get("browseDirectory") or "Backups",
        authorized_keys_file=data.get("authorizedKeysFile"),
        handoff=data.get("handoff"),
    )
