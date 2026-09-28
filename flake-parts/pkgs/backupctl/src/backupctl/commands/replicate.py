"""`backupctl replicate`: copy new snapshots into the local replicas."""

from __future__ import annotations

import argparse
from pathlib import Path

from backupctl import restic
from backupctl.config import Config
from backupctl.errors import UsageError


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `replicate` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "replicate",
        help="copy new snapshots into the local replicas",
        description=(
            "Copy snapshots missing in the local replica (restic copy), initializing the "
            "replica with the repository's chunker parameters on first use."
        ),
    )
    parser.add_argument(
        "repos", nargs="*", metavar="repo", help="repositories (default: all with a replica)"
    )
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Replicate the selected repositories.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 on success.

    Raises:
        UsageError: No replica root is configured or it is not available.
    """
    if config.replica_root is None:
        raise UsageError("no replicaRoot configured on this host")
    repos = config.select(args.repos, require_replica=True)

    try:
        Path(config.replica_root).mkdir(parents=True, exist_ok=True)
    except OSError as err:
        raise UsageError(
            f"replica root {config.replica_root} is not available ({err.strerror}), "
            "is the disk attached?"
        ) from err

    for repo in repos:
        source = restic.from_repo_args(repo)
        if not restic.replica_ready(repo):
            print(f"== {repo.name}: initializing the replica at {repo.replica}")
            restic.run(
                restic.command(config, repo, "init", "--copy-chunker-params", *source, replica=True)
            )
        print(f"== {repo.name}: copying new snapshots")
        restic.run(
            restic.command(config, repo, "copy", "--retry-lock", "30m", *source, replica=True)
        )
    return 0
