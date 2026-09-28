"""Building and running restic command lines."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

from backupctl.config import Config, Repository
from backupctl.errors import UsageError


def repo_args(repo: Repository, *, replica: bool = False) -> list[str]:
    """Global restic arguments selecting a repository.

    Args:
        repo: Repository to address.
        replica: Address the local replica instead of the repository itself.

    Returns:
        `--repo`, `--password-file` and, for the repository itself, its `-o`
        extended options.

    Raises:
        UsageError: `replica` is requested but the repository has none.
    """
    if replica:
        if repo.replica is None:
            raise UsageError(f"repository {repo.name!r} has no replica configured")
        return ["--repo", repo.replica, "--password-file", repo.password_file]
    return ["--repo", repo.repository, "--password-file", repo.password_file, *_options(repo)]


def from_repo_args(repo: Repository) -> list[str]:
    """Arguments naming a repository as the source of `copy` / `init`.

    Args:
        repo: Source repository.

    Returns:
        `--from-repo`, `--from-password-file` and its `-o` extended options.
    """
    return [
        "--from-repo",
        repo.repository,
        "--from-password-file",
        repo.password_file,
        *_options(repo),
    ]


def _options(repo: Repository) -> list[str]:
    return [arg for key, value in repo.options.items() for arg in ("-o", f"{key}={value}")]


def command(config: Config, repo: Repository, *args: str, replica: bool = False) -> list[str]:
    """Full restic argv for a repository.

    Args:
        config: Parsed config (for the restic binary).
        repo: Repository to address.
        *args: Subcommand and its arguments.
        replica: Address the local replica instead.

    Returns:
        The argv, ready for `run` or `exec_`.
    """
    return [config.restic, *repo_args(repo, replica=replica), *args]


def run(argv: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    """Run a command, failing loudly.

    Args:
        argv: Command to run.
        capture: Capture stdout (as text) instead of passing it through.

    Returns:
        The completed process.

    Raises:
        subprocess.CalledProcessError: The command exited non-zero.
    """
    return subprocess.run(argv, check=True, text=True, stdout=subprocess.PIPE if capture else None)


def exec_(argv: list[str]) -> NoReturn:
    """Replace the current process, handing it the terminal (and Ctrl-C).

    Args:
        argv: Command to execute.
    """
    sys.stdout.flush()
    os.execv(argv[0], argv)


def available(path: str | Path) -> bool:
    """Whether a path is reachable, without tripping over a missing automount.

    Args:
        path: Path to probe.

    Returns:
        `True` if the path exists and can be stat'ed.
    """
    try:
        return Path(path).exists()
    except OSError:
        return False


def replica_ready(repo: Repository) -> bool:
    """Whether the repository has an initialized, reachable replica.

    Args:
        repo: Repository whose replica to probe.

    Returns:
        `True` if the replica's `config` file is reachable.
    """
    return repo.replica is not None and available(Path(repo.replica) / "config")
