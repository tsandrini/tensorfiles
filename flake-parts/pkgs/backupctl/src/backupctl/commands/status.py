"""`backupctl status`: newest snapshot and its age, per repository and replica."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from backupctl import restic
from backupctl.config import Config, Repository


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
            "if attached, its replica. Exits 1 unless every repository (not replica) is "
            "reachable and its newest snapshot is younger than --max-age."
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


def row(
    config: Config, repo: Repository, *, replica: bool, now: datetime, max_age: float
) -> tuple[list[str], bool]:
    """Status of one copy of a repository.

    Args:
        config: Parsed config.
        repo: Repository to inspect.
        replica: Inspect the replica instead of the repository.
        now: Reference time for the age.
        max_age: Age in hours after which the copy is stale.

    Returns:
        The table row (repository, copy, snapshots, newest, age, state) and
        whether the copy is healthy.
    """
    label = "replica" if replica else "storage box"
    if replica and not restic.replica_ready(repo):
        # `<mount>/<replicaRoot>/<repo>`; the root only appears with the first `replicate`
        mount = Path(repo.replica or "/").parent.parent
        state = "not initialized" if restic.listable(mount) else "not attached"
        return [repo.name, label, "-", "-", "-", state], False

    try:
        out = restic.run(
            config, repo, "--no-lock", "snapshots", "--json", replica=replica, capture=True
        )
    except restic.ResticError as err:
        return [repo.name, label, "-", "-", "-", err.reason], False

    snapshots = json.loads(out or "null")
    latest = newest(snapshots)
    if latest is None:
        return [repo.name, label, "0", "-", "-", "empty"], False

    age = (now - latest).total_seconds() / 3600
    stale = age > max_age
    cells = [
        repo.name,
        label,
        str(len(snapshots)),
        latest.astimezone().strftime("%Y-%m-%d %H:%M"),
        f"{age:.1f}h",
        "stale" if stale else "ok",
    ]
    return cells, not stale


def run(config: Config, args: argparse.Namespace) -> int:
    """Print the status table.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 if every repository (replicas are informative) is healthy, 1 otherwise.
    """
    now = datetime.now(UTC)
    rows = [["REPOSITORY", "COPY", "SNAPSHOTS", "NEWEST", "AGE", "STATE"]]
    healthy = True

    for repo in config.select(args.repos):
        cells, ok = row(config, repo, replica=False, now=now, max_age=args.max_age)
        rows.append(cells)
        healthy = healthy and ok
        if repo.replica is not None:
            # replicas are refreshed by hand, so their age never fails the check
            cells, _ = row(config, repo, replica=True, now=now, max_age=float("inf"))
            rows.append(cells)

    widths = [max(len(cells[i]) for cells in rows) for i in range(len(rows[0]))]
    for cells in rows:
        print("  ".join(c.ljust(w) for c, w in zip(cells, widths, strict=True)).rstrip())
    return 0 if healthy else 1
