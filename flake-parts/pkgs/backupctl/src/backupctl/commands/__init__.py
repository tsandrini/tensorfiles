"""Subcommands.

Every module exposes `register(subparsers)`, which adds its parser and sets
`func` to a `run(config, args) -> int` callable.
"""

from backupctl.commands import browse, maintain, passthrough, replicate, status, sync_keys

MODULES = (status, browse, replicate, maintain, sync_keys, passthrough)
