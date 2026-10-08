"""`handoff push`: send local working trees to the relay."""

from __future__ import annotations

import argparse

from handoff.commands._common import add_relay_option, engine_for, report
from handoff.config import Config
from handoff.engine import local_units, select


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `push` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "push",
        help="copy local repositories to the relay",
        description=(
            "Copy every changed local unit (git repositories with their whole .git, plain "
            "directories wholesale) to its canonical copy on the relay. Refuses a repository whose "
            "relay copy moved on since this host last synced it."
        ),
    )
    parser.add_argument("units", nargs="*", metavar="unit", help="unit ids or `bundle/` prefixes")
    parser.add_argument(
        "--force", action="store_true", help="overwrite a relay copy this host did not sync from"
    )
    parser.add_argument("-n", "--dry-run", action="store_true", help="only report")
    add_relay_option(parser)
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Push.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 when nothing was skipped or in conflict, 1 otherwise.
    """
    units = local_units(config)
    chosen = select(args.units, [u.id for u in units])
    units = [u for u in units if u.id in chosen]
    with engine_for(config, args) as engine:
        outcomes = engine.push(units, force=args.force, dry_run=args.dry_run)
    return report(outcomes, quiet_actions=frozenset({"unchanged"}))
