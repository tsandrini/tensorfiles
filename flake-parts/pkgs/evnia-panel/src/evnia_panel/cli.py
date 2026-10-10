"""Command-line entry point: the panel by default, scriptable subcommands otherwise."""

from __future__ import annotations

import argparse
import json
import logging
import sys

from evnia_panel import __version__, items, monitor
from evnia_panel.monitor import Monitor, MonitorError, State


def _render(mon: Monitor, state: State, only: str | None = None) -> str:
    lines = [
        f"{'picture-mode':<22} {mon.mode_label(state.mode)} ({state.mode:02X})"
        if state.mode is not None
        else "picture-mode  unknown"
    ]
    section = None
    for item in items.ITEMS:
        if only is not None and item.section != only:
            continue
        if item.section != section:
            section = item.section
            lines.append(f"\n[{dict(items.SECTIONS)[section]}]")
        reading = state.values.get(item.id)
        value = item.label_for(None if reading is None else reading.value)
        flag = "" if item.writable else "  (read-only)"
        lines.append(f"{item.id:<22} {value}{flag}")
    host = f"{state.ambiglow.mode} {monitor.format_rgb(state.ambiglow.color)} (last host-set)"
    lines.append(f"\n{'ambiglow-host':<22} {host}")
    return "\n".join(lines)


def _to_json(state: State) -> str:
    return json.dumps(
        {
            "picture-mode": state.mode,
            "items": {k: {"value": v.value, "max": v.maximum} for k, v in state.values.items()},
            "ambiglow-host": {
                "mode": state.ambiglow.mode,
                "color": monitor.format_rgb(state.ambiglow.color),
            },
        },
        indent=2,
    )


def cmd_get(mon: Monitor, args: argparse.Namespace) -> int:
    state = mon.read(args.section)
    print(_to_json(state) if args.json else _render(mon, state, args.section))
    return 0


def cmd_items(_mon: Monitor, _args: argparse.Namespace) -> int:
    for section, title in items.SECTIONS:
        print(f"[{title}]")
        for item in items.in_section(section):
            if item.kind == items.RANGE and item.span:
                values = f"{item.span[0]}-{item.span[1]}"
            elif item.kind == items.INFO:
                values = "(info)"
            else:
                values = " | ".join(item.values.values())
            ro = "" if item.writable else " [read-only]"
            print(f"  {item.id:<22} {values}{ro}")
    return 0


def cmd_set(mon: Monitor, args: argparse.Namespace) -> int:
    item = items.BY_ID.get(args.item)
    if item is None:
        raise MonitorError(f"unknown item {args.item!r}; see `evnia-panel items`")
    try:
        value = item.parse(args.value)
    except ValueError as exc:
        raise MonitorError(str(exc)) from exc
    read = mon.set_item(item.id, value)
    print(f"{item.id} = {item.label_for(read.value)}")
    return 0


def cmd_mode(mon: Monitor, args: argparse.Namespace) -> int:
    try:
        value = mon.mode_value(args.mode)
    except ValueError as exc:
        raise MonitorError(str(exc)) from exc
    read = mon.set_mode(value)
    print(f"picture-mode = {mon.mode_label(read)}")
    return 0


def cmd_power(mon: Monitor, args: argparse.Namespace) -> int:
    read = mon.set_power(args.state == "on")
    print(f"power = {'on' if read == monitor.POWER_ON else f'{read:02X}'}")
    return 0


def cmd_ambiglow(mon: Monitor, args: argparse.Namespace) -> int:
    if args.target == "monitor":
        state = mon.ambiglow_monitor()
    elif args.target == "off":
        state = mon.ambiglow_off()
    else:
        if not args.color:
            raise MonitorError("solid needs a colour: rrggbb or a palette name")
        try:
            rgb = monitor.parse_rgb(args.color)
        except ValueError as exc:
            raise MonitorError(str(exc)) from exc
        state = mon.ambiglow_solid(rgb)
    print(f"ambiglow-host {state.mode} {monitor.format_rgb(state.color)}")
    return 0


def cmd_raw(mon: Monitor, args: argparse.Namespace) -> int:
    # NOTE: read-only on purpose; writes go through the item table
    addr = int(args.address, 16)
    try:
        reading = mon.ddc.get_sub(addr) if args.sub else mon.ddc.get_vcp(addr)
    except Exception as exc:
        raise MonitorError(str(exc)) from exc
    print(f"{'E2A0' if args.sub else 'VCP '}{addr:02X} = {reading.value} (max {reading.maximum})")
    return 0


IDENTITY_LABELS = {
    "name": "Model",
    "serial": "Serial",
    "manufacturer": "Manufacturer",
    "product": "Product code",
    "week": "Made (week)",
    "year": "Made (year)",
    "connector": "Connector",
    "ddc-bus": "DDC/CI bus",
    "lamparray": "Ambiglow LampArray",
}


def cmd_info(mon: Monitor, _args: argparse.Namespace) -> int:
    for key, value in mon.identity().items():
        print(f"{IDENTITY_LABELS.get(key, key):<26} {value}")
    state = mon.read("info")
    for item in items.in_section("info"):
        reading = state.values.get(item.id)
        print(f"{item.label:<26} {item.label_for(None if reading is None else reading.value)}")
    return 0


def cmd_panel(mon: Monitor, args: argparse.Namespace) -> int:
    from evnia_panel import ui

    return ui.run(mon, daemon=args.daemon)


def build_parser() -> argparse.ArgumentParser:
    """Build the argument parser.

    Returns:
        The parser; subcommands set ``func``.
    """
    parser = argparse.ArgumentParser(
        prog="evnia-panel",
        description="Control the Philips Evnia 32M2N8900P: a keyboard-driven overlay panel "
        "(default) or scriptable subcommands over DDC/CI and the USB Ambiglow LampArray.",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    parser.add_argument("--bus", type=int, help="I2C bus number (skips monitor detection)")
    parser.add_argument("-v", "--verbose", action="store_true", help="debug logging on stderr")
    parser.add_argument(
        "--daemon",
        action="store_true",
        help="stay resident with the panel hidden; later launches (or evnia-panel-toggle) toggle it",
    )
    sub = parser.add_subparsers(dest="command", metavar="command")

    sub.add_parser("panel", help="open or toggle the overlay panel (default)").set_defaults(func=cmd_panel)

    p = sub.add_parser("get", help="print the current state")
    p.add_argument("--json", action="store_true")
    p.add_argument("--section", choices=[s for s, _ in items.SECTIONS], help="only this menu section")
    p.set_defaults(func=cmd_get)

    sub.add_parser("items", help="list every item with its allowed values").set_defaults(func=cmd_items)
    sub.add_parser("info", help="identity (EDID), buses, OLED counters, versions").set_defaults(func=cmd_info)

    p = sub.add_parser("set", help="set one item: evnia-panel set light-mode 'color wave'")
    p.add_argument("item")
    p.add_argument("value", help="a label, on/off, a number, or hex")
    p.set_defaults(func=cmd_set)

    p = sub.add_parser("mode", help="set the picture mode (SmartImage, VCP DC)")
    p.add_argument("mode", help="label from the mode map or a hex value")
    p.set_defaults(func=cmd_mode)

    p = sub.add_parser("power", help="power the panel on, or into standby")
    p.add_argument("state", choices=("on", "off"))
    p.set_defaults(func=cmd_power)

    p = sub.add_parser(
        "ambiglow",
        help="host-side strip: monitor (hand back) | off | solid <rrggbb|palette name>",
    )
    p.add_argument("target", choices=("monitor", "off", "solid"))
    p.add_argument("color", nargs="?", help=f"rrggbb or one of {', '.join(monitor.PALETTE)}")
    p.set_defaults(func=cmd_ambiglow)

    p = sub.add_parser("raw", help="read one VCP code (or --sub address) for research")
    p.add_argument("address", help="hex")
    p.add_argument("--sub", action="store_true", help="E2 A0xx sub-feature instead of a VCP code")
    p.set_defaults(func=cmd_raw)

    parser.set_defaults(func=cmd_panel)
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run the CLI.

    Args:
        argv: Arguments without the program name; ``sys.argv[1:]`` when ``None``.

    Returns:
        0 on success, 2 on a usage error or when the monitor refused/failed.
    """
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING, format="evnia-panel: %(message)s"
    )
    try:
        mon = Monitor(bus=args.bus)
        return args.func(mon, args)
    except MonitorError as exc:
        print(f"evnia-panel: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130
