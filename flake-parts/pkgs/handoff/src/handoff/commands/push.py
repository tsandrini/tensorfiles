"""`handoff push`: send local working trees to the relay."""

from __future__ import annotations

import argparse

from handoff.commands._common import (
    add_relay_option,
    engine_for,
    merge_engine,
    report,
    split_selection,
)
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
    parser.add_argument(
        "units", nargs="*", metavar="unit", help="unit ids, `bundle/` prefixes, or `claude`"
    )
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
    requested, want_units, want_claude = split_selection(args.units)
    units = local_units(config)
    chosen = select(requested, [u.id for u in units]) if want_units else []
    units = [u for u in units if u.id in chosen]
    with engine_for(config, args) as engine:
        code = 0
        if want_units:
            outcomes = engine.push(units, force=args.force, dry_run=args.dry_run)
            code = report(outcomes, quiet_actions=frozenset({"unchanged"}))
        merge = merge_engine(config, engine) if want_claude else None
        if merge is not None:
            result = merge.push(dry_run=args.dry_run)
            print(result.summary("would push" if args.dry_run else "pushed"))
            code = code or (1 if result.problem else 0)
    return code
