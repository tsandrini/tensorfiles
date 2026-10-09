"""`handoff pull`: bring the relay's canonical copies into the local working trees."""

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
    parser.add_argument(
        "units", nargs="*", metavar="unit", help="unit ids, `bundle/` prefixes, or `claude`"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Claude state: consider every relay file, not only pushes since the last pull",
    )
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
    requested, want_units, want_claude = split_selection(args.units)
    with engine_for(config, args) as engine:
        code = 0
        if want_units:
            known = [uid for uid in sorted(engine.meta) if config.workspace.selects(uid)]
            chosen = select(requested, known)
            outcomes = engine.pull(
                chosen,
                take_relay=args.take_relay,
                keep_local=args.keep_local,
                dry_run=args.dry_run,
            )
            code = report(outcomes, quiet_actions=frozenset({"up to date"}))
        merge = merge_engine(config, engine) if want_claude else None
        if merge is not None:
            result = merge.pull(everything=args.all, dry_run=args.dry_run)
            print(result.summary("would pull" if args.dry_run else "pulled"))
            code = code or (1 if result.problem else 0)
    return code
