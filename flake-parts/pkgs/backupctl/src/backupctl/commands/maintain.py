"""`backupctl maintain`: apply the retention policy and verify the repositories."""

from __future__ import annotations

import argparse

from backupctl import restic
from backupctl.config import Config
from backupctl.errors import UsageError


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `maintain` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "maintain",
        help="forget --prune by the retention policy, then check",
        description=(
            "Apply the retention policy (restic forget --prune) and verify a random subset "
            "of the data (restic check --read-data-subset), on every repository and its "
            "replica if attached. Needs full (not append-only) access."
        ),
    )
    parser.add_argument("repos", nargs="*", metavar="repo", help="repositories (default: all)")
    parser.add_argument(
        "--read-data-subset",
        metavar="SUBSET",
        help="override the configured check subset, e.g. 10%% or 1/5",
    )
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Maintain the selected repositories.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 on success.

    Raises:
        UsageError: No retention policy is configured, or a selected
            repository is only reachable append-only from this host.
    """
    if not config.retention:
        raise UsageError("no retention policy configured, refusing to run forget")
    repos = config.select(args.repos)
    if refused := [repo.name for repo in repos if repo.append_only]:
        raise UsageError(
            f"only append-only access to {', '.join(refused)} here, "
            "run maintain from a host with full access"
        )
    subset = args.read_data_subset or config.check_read_data_subset

    for repo in repos:
        copies = [("storage box", False)]
        if repo.replica is not None:
            copies.append(("replica", True))

        for label, replica in copies:
            if replica and not restic.replica_ready(repo):
                print(f"== {repo.name} ({label}): not available, skipping")
                continue
            print(f"== {repo.name} ({label}): forget --prune")
            restic.run(
                config,
                repo,
                "forget",
                "--prune",
                "--retry-lock",
                "30m",
                *config.retention,
                replica=replica,
            )
            print(f"== {repo.name} ({label}): check --read-data-subset {subset}")
            restic.run(
                config,
                repo,
                "check",
                "--retry-lock",
                "30m",
                "--read-data-subset",
                subset,
                replica=replica,
            )
    return 0
