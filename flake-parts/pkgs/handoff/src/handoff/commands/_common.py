"""Helpers shared by the subcommands."""

from __future__ import annotations

import argparse
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from handoff.config import Config
from handoff.engine import Engine, Outcome
from handoff.merge import NAME as CLAUDE
from handoff.merge import MergeEngine
from handoff.state import StateStore
from handoff.store import Store


def add_relay_option(parser: argparse.ArgumentParser) -> None:
    """Add `--relay` to a subcommand parser.

    Args:
        parser: The subcommand parser.
    """
    parser.add_argument("--relay", metavar="NAME", help="relay to use (default: relay.default)")


@contextmanager
def engine_for(config: Config, args: argparse.Namespace) -> Iterator[Engine]:
    """Build an engine with a scratch directory that lives for the command.

    Args:
        config: Parsed config.
        args: Parsed command line (uses `relay`).

    Yields:
        The engine.
    """
    relay_cfg = config.relay(args.relay)
    with tempfile.TemporaryDirectory(prefix="handoff-") as tmp:
        store = Store(relay_cfg, Path(tmp))
        state = StateStore(config.state_dir, relay_cfg.name)
        yield Engine(config, store, state)


def merge_engine(config: Config, engine: Engine) -> MergeEngine | None:
    """The Claude-state engine sharing the relay and state of `engine`.

    Args:
        config: Parsed config.
        engine: The repository engine of this command.

    Returns:
        The merge engine, `None` when `[claude]` is not configured.
    """
    if config.claude is None:
        return None
    return MergeEngine(config, config.claude, engine.store, engine.state)


def split_selection(requested: list[str]) -> tuple[list[str], bool, bool]:
    """Separate the `claude` pseudo-unit from repository selections.

    Args:
        requested: Positional unit arguments.

    Returns:
        The repository selections (empty means all), whether repositories are
        wanted at all, and whether Claude state is wanted. Nothing requested
        means everything.
    """
    units = [u for u in requested if u != CLAUDE]
    return units, not requested or bool(units), not requested or CLAUDE in requested


def report(outcomes: list[Outcome], *, quiet_actions: frozenset[str] = frozenset()) -> int:
    """Print outcomes, one per line, and derive the exit code.

    Args:
        outcomes: What happened per unit.
        quiet_actions: Actions not worth a line.

    Returns:
        1 if any unit failed, was skipped or is in conflict, 0 otherwise.
    """
    width = max((len(o.unit_id) for o in outcomes), default=0)
    for o in outcomes:
        if o.action in quiet_actions:
            continue
        line = f"{o.unit_id.ljust(width)}  {o.action}"
        if o.detail:
            line += f": {o.detail}"
        print(line)
    counts: dict[str, int] = {}
    for o in outcomes:
        counts[o.action] = counts.get(o.action, 0) + 1
    print(
        "summary: " + ", ".join(f"{n} {a}" for a, n in sorted(counts.items()))
        if counts
        else "nothing to do"
    )
    return 1 if any(o.failed for o in outcomes) else 0
