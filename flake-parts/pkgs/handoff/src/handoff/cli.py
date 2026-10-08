"""Command-line entry point."""

from __future__ import annotations

import argparse
import logging
import sys

from handoff import __version__, commands
from handoff.config import CONFIG_ENV, default_config_path, load, resolve_path
from handoff.errors import HandoffError, RelayError


def build_parser() -> argparse.ArgumentParser:
    """Build the top-level parser with all subcommands.

    Returns:
        The parser.
    """
    parser = argparse.ArgumentParser(
        prog="handoff",
        description=(
            "Carry dirty git working trees between machines through an encrypted rclone relay: "
            "push before you leave, pull when you arrive."
        ),
    )
    parser.add_argument(
        "--config",
        metavar="PATH",
        help=f"config file (default: ${CONFIG_ENV}, then {default_config_path()})",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="print the rclone commands being run"
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    subparsers = parser.add_subparsers(dest="command", required=True, metavar="command")
    for module in commands.MODULES:
        module.register(subparsers)
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run handoff.

    Args:
        argv: Arguments without the program name, `sys.argv[1:]` when `None`.

    Returns:
        Process exit code: 0 on success, 1 when a unit was skipped or is in
        conflict or the relay failed, 2 for a usage or config error, 130 when
        interrupted.
    """
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="handoff: %(message)s",
    )
    try:
        config = load(resolve_path(args.config))
        return args.func(config, args)
    except RelayError as err:
        print(f"handoff: {err}", file=sys.stderr)
        return 1
    except HandoffError as err:
        print(f"handoff: {err}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130
