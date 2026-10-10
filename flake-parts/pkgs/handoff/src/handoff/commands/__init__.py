"""Subcommands.

Every module exposes `register(subparsers)`, which adds its parser and sets
`func` to a `run(config, args) -> int` callable.
"""

from handoff.commands import pull, push, status, verify

MODULES = (status, push, pull, verify)
