"""`backupctl restic`: plain restic against a configured repository."""

from __future__ import annotations

import argparse

from backupctl import restic
from backupctl.config import Config


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `restic` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "restic",
        help="run plain restic against a repository",
        description=(
            "Run restic with the repository, password and connection options filled in. "
            "Everything after the repository name is passed to restic verbatim, e.g. "
            "`backupctl restic remotebundle snapshots` or "
            "`backupctl restic --replica remotebundle restore latest --include /var/vmail "
            "--target /tmp/r`."
        ),
    )
    parser.add_argument(
        "--replica", action="store_true", help="use the local replica (before the repository)"
    )
    parser.add_argument("repo", help="repository to run against")
    parser.add_argument("args", nargs=argparse.REMAINDER, help="restic subcommand and arguments")
    parser.set_defaults(func=run)


def restic_args(args: list[str]) -> list[str]:
    """Strip an optional leading `--` separator.

    Args:
        args: Arguments captured after the repository name.

    Returns:
        The arguments for restic.
    """
    return args[1:] if args[:1] == ["--"] else args


def run(config: Config, args: argparse.Namespace) -> int:
    """Replace the current process with restic.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        Never returns on success.
    """
    [repo] = config.select([args.repo])
    restic.exec_(config, repo, *restic_args(args.args), replica=args.replica)
