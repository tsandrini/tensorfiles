"""`handoff pull`: bring the relay's canonical copies into the local working trees."""

from __future__ import annotations

import argparse

from handoff.commands._common import add_relay_option, engine_for, report
from handoff.config import Config
from handoff.engine import select


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `pull` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "pull",
        help="copy the relay's repositories into the local workspace",
        description=(
            "Bring every repository the relay knows into the local workspace. A local copy "
            "with changes since its last sync is first set aside under conflicts/ on the "
            "relay, unless --take-relay or --keep-local say otherwise."
        ),
    )
    parser.add_argument("units", nargs="*", metavar="unit", help="unit ids or `bundle/` prefixes")
    parser.add_argument(
        "--take-relay",
        action="store_true",
        help="overwrite local changes without setting them aside",
    )
    parser.add_argument(
        "--keep-local", action="store_true", help="skip repositories with local changes"
    )
    parser.add_argument("-n", "--dry-run", action="store_true", help="only report")
    add_relay_option(parser)
    parser.set_defaults(func=run)


def run(config: Config, args: argparse.Namespace) -> int:
    """Pull.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 when nothing was skipped or in conflict, 1 otherwise.
    """
    with engine_for(config, args) as engine:
        known = [uid for uid in sorted(engine.meta) if config.workspace.selects(uid)]
        chosen = select(args.units, known)
        outcomes = engine.pull(
            chosen, take_relay=args.take_relay, keep_local=args.keep_local, dry_run=args.dry_run
        )
    return report(outcomes, quiet_actions=frozenset({"up to date"}))
