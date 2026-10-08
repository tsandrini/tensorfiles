"""`handoff status`: where every unit stands relative to the relay."""

from __future__ import annotations

import argparse
import json
from datetime import datetime

from handoff.commands._common import add_relay_option, engine_for
from handoff.config import Config
from handoff.engine import UnitStatus, local_units, select

HEALTHY = frozenset({"in sync", "unadopted"})


def register(subparsers: argparse._SubParsersAction) -> None:
    """Add the `status` subcommand.

    Args:
        subparsers: Subparsers of the top-level parser.
    """
    parser = subparsers.add_parser(
        "status",
        help="show which units need a push or a pull",
        description=(
            "Compare every local repository and every canonical copy on the relay against "
            "the last sync. Exits 1 unless everything is in sync."
        ),
    )
    parser.add_argument("units", nargs="*", metavar="unit", help="unit ids or `bundle/` prefixes")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    add_relay_option(parser)
    parser.set_defaults(func=run)


def local_time(iso: str | None) -> str:
    """Render an ISO timestamp in local time.

    Args:
        iso: ISO timestamp, or `None`.

    Returns:
        `YYYY-MM-DD HH:MM`, or `-`.
    """
    if not iso:
        return "-"
    return datetime.fromisoformat(iso).astimezone().strftime("%Y-%m-%d %H:%M")


def table(rows: list[UnitStatus]) -> str:
    """Render the status table.

    Args:
        rows: Status rows.

    Returns:
        The table text.
    """
    cells = [["UNIT", "KIND", "LOCAL", "RELAY", "STATE"]]
    for r in rows:
        relay = f"{r.relay_host} {local_time(r.relay_time)}" if r.relay_host else "-"
        cells.append([r.unit_id, r.kind, r.local, relay, r.state])
    widths = [max(len(c[i]) for c in cells) for i in range(5)]
    return "\n".join(
        "  ".join(c.ljust(w) for c, w in zip(line, widths, strict=True)).rstrip() for line in cells
    )


def run(config: Config, args: argparse.Namespace) -> int:
    """Print the status.

    Args:
        config: Parsed config.
        args: Parsed command line.

    Returns:
        0 when every unit is in sync, 1 otherwise.
    """
    units = local_units(config)
    with engine_for(config, args) as engine:
        rows = engine.status(units)
        relay_name = engine.store.cfg.name
    if args.units:
        chosen = select(args.units, [r.unit_id for r in rows])
        rows = [r for r in rows if r.unit_id in chosen]
    healthy = all(r.state in HEALTHY for r in rows)

    if args.json:
        print(
            json.dumps(
                {
                    "relay": relay_name,
                    "host": config.host,
                    "healthy": healthy,
                    "units": [r.__dict__ for r in rows],
                },
                indent=2,
            )
        )
        return 0 if healthy else 1

    print(table(rows))
    return 0 if healthy else 1
