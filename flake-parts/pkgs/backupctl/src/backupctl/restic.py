"""Building and running restic command lines."""

from __future__ import annotations

import json
import logging
import os
import shlex
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

from backupctl.config import Config, Repository
from backupctl.errors import BackupctlError, UsageError

log = logging.getLogger(__name__)

# restic >= 0.17 exit codes, see `restic --help`
EXIT_REASONS = {
    1: "fatal error",
    3: "some source files could not be read",
    10: "repository does not exist",
    11: "repository is locked",
    12: "wrong password",
    130: "interrupted",
}


class ResticError(BackupctlError):
    """A restic invocation exited non-zero.

    Attributes:
        repo: Name of the repository it ran against.
        subcommand: restic subcommand, e.g. `snapshots`.
        replica: Whether it ran against the replica.
        returncode: restic exit code.
        reason: Human-readable meaning of the exit code.
        detail: restic's own error message, if it was captured.
    """

    def __init__(
        self,
        repo: str,
        subcommand: str,
        replica: bool,
        returncode: int,
        detail: str | None = None,
    ) -> None:
        self.repo = repo
        self.subcommand = subcommand
        self.replica = replica
        self.returncode = returncode
        self.reason = EXIT_REASONS.get(returncode, f"exit code {returncode}")
        self.detail = detail
        where = f"{repo} (replica)" if replica else repo
        super().__init__(f"`restic {subcommand}` on {where}: {self.reason}")


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
        The argv.
    """
    return [config.restic, *repo_args(repo, replica=replica), *args]


def subcommand(args: tuple[str, ...] | list[str]) -> str:
    """The restic subcommand among the arguments (the first non-option).

    Args:
        args: Arguments following the repository selection.

    Returns:
        The subcommand, `restic` if there is none.
    """
    return next((arg for arg in args if not arg.startswith("-")), "restic")


def error_detail(stderr: str) -> str | None:
    """restic's own error message from captured stderr.

    Args:
        stderr: Captured standard error; with `--json` restic reports fatal
            errors as `{"message_type": "exit_error", ...}` lines.

    Returns:
        The first line of the message, `None` if there is nothing useful.
    """
    lines = [line.strip() for line in stderr.splitlines() if line.strip()]
    for line in lines:
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(message, dict) and message.get("message_type") == "exit_error":
            return str(message.get("message", "")).splitlines()[0] or None
    return lines[-1] if lines else None


def run(
    config: Config,
    repo: Repository,
    *args: str,
    replica: bool = False,
    capture: bool = False,
) -> str | None:
    """Run restic against a repository, failing loudly.

    Args:
        config: Parsed config.
        repo: Repository to address.
        *args: Subcommand and its arguments.
        replica: Address the local replica instead.
        capture: Capture stdout and stderr instead of passing them through.

    Returns:
        Captured stdout, `None` when not capturing.

    Raises:
        ResticError: restic exited non-zero.
    """
    argv = command(config, repo, *args, replica=replica)
    log.debug("running %s", shlex.join(argv))
    pipe = subprocess.PIPE if capture else None
    proc = subprocess.run(argv, text=True, stdout=pipe, stderr=pipe, check=False)
    if proc.returncode != 0:
        detail = error_detail(proc.stderr) if capture else None
        raise ResticError(repo.name, subcommand(args), replica, proc.returncode, detail)
    return proc.stdout if capture else None


def exec_(config: Config, repo: Repository, *args: str, replica: bool = False) -> NoReturn:
    """Replace the current process with restic, handing it the terminal (and Ctrl-C).

    Args:
        config: Parsed config.
        repo: Repository to address.
        *args: Subcommand and its arguments.
        replica: Address the local replica instead.
    """
    argv = command(config, repo, *args, replica=replica)
    log.debug("executing %s", shlex.join(argv))
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


def listable(path: str | Path) -> bool:
    """Whether a directory can be listed.

    Unlike `available`, listing an automount point makes it mount, so this
    tells an attached disk from an absent one.

    Args:
        path: Directory to probe.

    Returns:
        `True` if the directory can be read.
    """
    try:
        with os.scandir(path) as entries:
            next(entries, None)
    except OSError:
        return False
    return True


def replica_ready(repo: Repository) -> bool:
    """Whether the repository has an initialized, reachable replica.

    Args:
        repo: Repository whose replica to probe.

    Returns:
        `True` if the replica's `config` file is reachable.
    """
    return repo.replica is not None and available(Path(repo.replica) / "config")
