"""`backupctl status`: newest snapshot and its age, per repository and replica."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from typing import Any

from backupctl import restic
from backupctl.config import Config


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `status` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "status",
        help="show the newest snapshot and its age per repository",
        description=(
            "Show snapshot count, newest snapshot and its age for every repository and, "
            "if attached, its replica. Exits 1 if a repository (not a replica) has no "
            "snapshot or its newest one is older than --max-age."
        ),
    )
    parser.add_argument("repos", nargs="*", metavar="repo", help="repositories (default: all)")
    parser.add_argument(
        "--max-age",
        type=float,
        default=26.0,
        metavar="HOURS",
        help="age after which a repository counts as stale (default: %(default)s)",
    )
    parser.set_defaults(func=run)


def newest(snapshots: list[dict[str, Any]] | None) -> datetime | None:
    """Time of the newest snapshot.

    Args:
        snapshots: Decoded `restic snapshots --json` output (may be `null`).

    Returns:
        The newest snapshot time, `None` if there are no snapshots.
    """
    return max((datetime.fromisoformat(s["time"]) for s in snapshots or []), default=None)


def run(config: Config, args: argparse.Namespace) -> int:
    """Print the status table.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 if every repository is fresh, 1 otherwise.
    """
    now = datetime.now(UTC)
    rows = [("REPOSITORY", "COPY", "SNAPSHOTS", "NEWEST", "AGE")]
    healthy = True

    for repo in config.select(args.repos):
        copies = [("storage box", False)]
        if repo.replica is not None:
            copies.append(("replica", True))

        for label, replica in copies:
            if replica and not restic.replica_ready(repo):
                rows.append((repo.name, label, "-", "not available", "-"))
                continue

            argv = restic.command(config, repo, "--no-lock", "snapshots", "--json", replica=replica)
            snapshots = json.loads(restic.run(argv, capture=True).stdout or "null")
            latest = newest(snapshots)
            if latest is None:
                rows.append((repo.name, label, "0", "-", "-"))
                if not replica:
                    healthy = False
                continue

            age = (now - latest).total_seconds() / 3600
            stale = not replica and age > args.max_age
            healthy = healthy and not stale
            rows.append(
                (
                    repo.name,
                    label,
                    str(len(snapshots)),
                    latest.astimezone().strftime("%Y-%m-%d %H:%M"),
                    f"{age:.1f}h" + (" STALE" if stale else ""),
                )
            )

    widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]
    for row in rows:
        print(
            "  ".join(cell.ljust(width) for cell, width in zip(row, widths, strict=True)).rstrip()
        )
    return 0 if healthy else 1
