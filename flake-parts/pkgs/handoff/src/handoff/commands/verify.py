"""`handoff verify`: compare file contents with the relay, not just stat data."""

from __future__ import annotations

import argparse

from handoff.commands._common import add_relay_option, engine_for, report, split_selection
from handoff.config import Config
from handoff.engine import local_units, select


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `verify` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "verify",
        help="hash local files and compare them with the relay",
        description=(
            "Hash every file of each in-sync unit and compare with the hashes recorded on the "
            "relay. Finds files whose content differs although size and mtime match (which "
            "push/pull cannot see). --fix restores them from the relay; --rehash publishes "
            "this host's hashes for units the relay has no hashes for yet (only on the host "
            "whose copies are known to be good)."
        ),
    )
    parser.add_argument("units", nargs="*", metavar="unit", help="unit ids or `bundle/` prefixes")
    parser.add_argument("--fix", action="store_true", help="restore mismatching files")
    parser.add_argument("--rehash", action="store_true", help="publish missing relay hashes")
    parser.add_argument("-n", "--dry-run", action="store_true", help="only report")
    add_relay_option(parser)
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Verify.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 when every checked unit matches, 1 otherwise.
    """
    requested, _, _ = split_selection(args.units)
    units = local_units(config)
    chosen = select(requested, [u.id for u in units])
    units = [u for u in units if u.id in chosen]
    with engine_for(config, args) as engine:
        outcomes = engine.verify(units, fix=args.fix, rehash=args.rehash, dry_run=args.dry_run)
    return report(outcomes, quiet_actions=frozenset({"verified"}))
