"""Command-line entry point."""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys

from backupctl import __version__, commands
from backupctl.config import CONFIG_ENV, DEFAULT_CONFIG_PATH, load, resolve_path
from backupctl.errors import BackupctlError


def build_parser() -> argparse.ArgumentParser:
    """Build the top-level parser with all subcommands.

    Returns:
        The parser.
    """
    parser = argparse.ArgumentParser(
        prog="backupctl",
        description=(
            "Browse, restore, replicate and maintain the restic repositories on the "
            "Storage Box. Scheduled backups are not handled here."
        ),
    )
    parser.add_argument(
        "--config",
        metavar="PATH",
        help=f"config file (default: ${CONFIG_ENV}, then {DEFAULT_CONFIG_PATH})",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    subparsers = parser.add_subparsers(dest="command", required=True, metavar="command")
    for module in commands.MODULES:
        module.register(subparsers)
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run backupctl.

    Args:
        argv: Arguments without the program name, `sys.argv[1:]` when `None`.

    Returns:
        Process exit code: 0 on success, 1 for a failed check or command,
        2 for a usage or config error, 130 when interrupted.
    """
    args = build_parser().parse_args(argv)
    try:
        config = load(resolve_path(args.config))
        return args.func(config, args)
    except BackupctlError as err:
        print(f"backupctl: {err}", file=sys.stderr)
        return 2
    except subprocess.CalledProcessError as err:
        cmd = err.cmd if isinstance(err.cmd, list) else [str(err.cmd)]
        print(f"backupctl: `{shlex.join(cmd)}` exited with {err.returncode}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
