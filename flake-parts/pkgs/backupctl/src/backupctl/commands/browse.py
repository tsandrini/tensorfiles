"""`backupctl browse`: FUSE-mount every snapshot of a repository as folders."""

from __future__ import annotations

import argparse
from pathlib import Path

from backupctl import restic
from backupctl.config import Config
from backupctl.errors import UsageError


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `browse` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "browse",
        help="mount every snapshot as folders under ~/<browseDirectory>",
        description=(
            "Mount the repository (read-only) under ~/<browseDirectory>/<repo>; every "
            "snapshot is a folder under snapshots/. Runs in the foreground, Ctrl-C unmounts."
        ),
    )
    parser.add_argument("repo", help="repository to mount")
    parser.add_argument("--replica", action="store_true", help="mount the local replica instead")
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Mount the repository, replacing the current process with `restic mount`.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        Never returns on success.

    Raises:
        UsageError: The requested replica is not available.
    """
    [repo] = config.select([args.repo])
    if args.replica and not restic.replica_ready(repo):
        raise UsageError(f"the replica of {repo.name!r} is not available (disk not attached?)")

    target = (
        Path.home()
        / config.browse_directory
        / (f"{repo.name}-replica" if args.replica else repo.name)
    )
    target.mkdir(parents=True, exist_ok=True)
    print(f"mounting {repo.name}{' (replica)' if args.replica else ''} at {target}")
    print("every snapshot is a folder under snapshots/, press Ctrl-C to unmount")
    restic.exec_(config, repo, "mount", str(target), replica=args.replica)
