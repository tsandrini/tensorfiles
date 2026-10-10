"""The overlay panel: GTK4 + libadwaita on a wlr-layer-shell surface.

Pages mirror the monitor's OSD sections and every row is generated from
:mod:`evnia_panel.items`, so the panel and the CLI can never disagree about
what exists or what is allowed. The application is unique per session
(GApplication): any further activation toggles the panel. With
``--daemon`` the window is built at login and kept hidden between summons,
so a toggle costs one DBus round trip instead of a ~500 ms Python + GTK cold
start; ``evnia-panel-toggle`` (shell, ``gdbus``) is the cheap summoner and
falls back to a plain launch when no daemon runs.

All monitor I/O runs on one worker thread; results are applied on the main
loop and always reflect the read-back, never the request. Sections are read
one after another so the first page fills within ~100 ms of opening.
"""

from __future__ import annotations

import contextlib
import ctypes
import json
import logging
import os
import subprocess
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from typing import Any

from evnia_panel import ddc, items, monitor
from evnia_panel.ddc import Reading
from evnia_panel.items import Item
from evnia_panel.monitor import AmbiglowState, Monitor, MonitorError, State

log = logging.getLogger("evnia-panel")

APP_ID = "sh.tsandrini.EvniaPanel"
#: Environment variable the Nix wrapper sets to the layer-shell library.
LAYER_SHELL_ENV = "EVNIA_PANEL_LAYER_SHELL"
_DEBOUNCE_MS = 200


def _preload_layer_shell() -> None:
    # NOTE: gtk4-layer-shell must be mapped before GTK loads libwayland-client,
    # which happens on `import gi.repository.Gtk`; RTLD_GLOBAL does the job
    # without LD_PRELOAD. https://github.com/wmww/gtk4-layer-shell/blob/main/compatibility.md
    with contextlib.suppress(OSError):
        ctypes.CDLL(os.environ.get(LAYER_SHELL_ENV, "libgtk4-layer-shell.so.0"), mode=ctypes.RTLD_GLOBAL)


_preload_layer_shell()

import gi  # noqa: E402

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Gdk", "4.0")
try:
    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gtk4LayerShell as LayerShell
except (ValueError, ImportError):  # pragma: no cover - only without the typelib
    LayerShell = None
from gi.repository import Adw, Gdk, GLib, Gtk  # noqa: E402


def _niri_focused_output() -> str | None:
    """Connector name of niri's focused output, ``None`` outside niri."""
    try:
        proc = subprocess.run(
            ["niri", "msg", "--json", "focused-output"],
            capture_output=True,
            text=True,
            check=False,
            timeout=2,
        )
        return json.loads(proc.stdout)["name"] if proc.returncode == 0 else None
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired):
        return None


def _niri_focus_output(name: str) -> bool:
    """Ask niri to focus an output. Returns ``False`` when that did not work."""
    try:
        proc = subprocess.run(
            ["niri", "msg", "action", "focus-monitor", name], capture_output=True, check=False, timeout=2
        )
        return proc.returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


_CSS = """
.swatch { min-width: 26px; min-height: 26px; border-radius: 7px; margin: 2px; }
.evnia-panel { border-radius: 14px; }
""" + "\n".join(
    f".swatch-{name} {{ background-color: #{monitor.format_rgb(rgb)}; }}"
    for name, rgb in monitor.PALETTE.items()
)


class PanelWindow(Adw.Window):
    """The panel window; one per application instance."""

    def __init__(self, app: Adw.Application, mon: Monitor) -> None:
        super().__init__(application=app, title="Evnia 32M2N8900P")
        self.mon = mon
        self._executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="evnia-io")
        self._syncing = False
        self._pending: dict[str, int] = {}
        self._focus_pending = True
        self._connector: str | None = None
        self._restore_output: str | None = None
        self._rows: dict[str, tuple[Item, Gtk.Widget]] = {}
        self._install_layer_shell()
        self.add_css_class("evnia-panel")
        self.set_default_size(1120, 1000)

        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self._on_key)
        self.add_controller(keys)
        self.connect("notify::is-active", lambda w, _p: log.debug("window active=%s", w.is_active()))

        self._stack = Adw.ViewStack()
        switcher = Adw.ViewSwitcher(stack=self._stack, policy=Adw.ViewSwitcherPolicy.WIDE)
        header = Adw.HeaderBar(title_widget=switcher, show_end_title_buttons=False)
        self._toasts = Adw.ToastOverlay(child=self._stack)
        view = Adw.ToolbarView(content=self._toasts)
        view.add_top_bar(header)
        self.set_content(view)

        for section, title in items.SECTIONS:
            page = Adw.PreferencesPage()
            if section == "smartimage":
                self._build_modes(page)
            if section == "info":
                self._build_identity(page)
            group = Adw.PreferencesGroup(title=title if section != "info" else "Panel health")
            for item in items.in_section(section):
                self._add_row(group, item)
            page.add(group)
            if section == "ambiglow":
                self._build_host_ambiglow(page)
            self._stack.add_titled_with_icon(page, section, title, items.ICONS[section])

        self.connect("close-request", lambda _w: self.dismiss())

    # --- plumbing ----------------------------------------------------------------

    def _install_layer_shell(self) -> None:
        if LayerShell is None or not LayerShell.is_supported():
            return
        LayerShell.init_for_window(self)
        LayerShell.set_namespace(self, "evnia-panel")
        LayerShell.set_layer(self, LayerShell.Layer.OVERLAY)
        LayerShell.set_keyboard_mode(self, LayerShell.KeyboardMode.EXCLUSIVE)
        display = Gdk.Display.get_default()
        for gdk_monitor in display.get_monitors():
            if ddc.MODEL in (gdk_monitor.get_model() or ""):
                LayerShell.set_monitor(self, gdk_monitor)
                self._connector = gdk_monitor.get_connector()
                break

    def _on_key(self, _ctrl: Gtk.EventControllerKey, keyval: int, _code: int, mod: Gdk.ModifierType) -> bool:
        log.debug("key %s", Gdk.keyval_name(keyval))
        if keyval == Gdk.KEY_Escape:
            self.dismiss()
            return True
        pages = [s for s, _ in items.SECTIONS]
        if mod & Gdk.ModifierType.CONTROL_MASK and keyval in (Gdk.KEY_Page_Up, Gdk.KEY_Page_Down):
            index = pages.index(self._stack.get_visible_child_name())
            index = (index + (1 if keyval == Gdk.KEY_Page_Down else -1)) % len(pages)
            self._show_page(pages[index])
            return True
        if mod & Gdk.ModifierType.ALT_MASK and Gdk.KEY_1 <= keyval < Gdk.KEY_1 + len(pages):
            self._show_page(pages[keyval - Gdk.KEY_1])
            return True
        return False

    def _show_page(self, section: str) -> None:
        self._stack.set_visible_child_name(section)
        if section == "smartimage":
            self.focus_mode()
            return
        # NOTE: explicit focus on the first writable row; GTK's own pick
        # can land on the palette flow box, which eats the arrow keys
        rows = items.in_section(section)
        for item in rows:
            if item.writable:
                self._rows[item.id][1].grab_focus()
                return
        if rows:
            self._rows[rows[0].id][1].grab_focus()

    def summon(self) -> None:
        """Show the panel, take keyboard focus and re-read the monitor.

        niri only hands exclusive layer-shell focus to surfaces on the
        focused output, so when the user is on another monitor the Evnia's
        output is focused first and the previous one restored on dismiss.
        """
        self.present()
        self.focus_mode()
        self.refresh()
        if self._connector is None:
            return
        current = _niri_focused_output()
        if current and current != self._connector and _niri_focus_output(self._connector):
            self._restore_output = current

    def dismiss(self) -> bool:
        """Hide (daemon) or quit (one-shot). Returns ``True`` to stop the close signal."""
        if self._restore_output is not None:
            _niri_focus_output(self._restore_output)
            self._restore_output = None
        app = self.get_application()
        if isinstance(app, PanelApplication) and app.daemon:
            self.set_visible(False)
        else:
            app.quit()
        return True

    def refresh(self) -> None:
        """Re-read every section from the monitor (async, section by section)."""
        self._focus_pending = True
        self._modes_group.set_description("SmartImage (VCP DC) · reading…")
        for section, _title in items.SECTIONS:
            self._async(lambda s=section: self.mon.read(s), self._on_state)

    def focus_mode(self, value: int | None = None) -> None:
        """Put keyboard focus on a picture mode row (the first one by default)."""
        rows = self._mode_rows
        row = rows.get(value) if value is not None else None
        if row is None and rows:
            row = next(iter(rows.values()))
        if row is not None:
            row.grab_focus()

    def _async(self, work: Callable[[], Any], done: Callable[[Any], None]) -> None:
        def task() -> None:
            try:
                result = work()
            except MonitorError as exc:
                GLib.idle_add(self._toast, str(exc))
            else:
                GLib.idle_add(lambda: (done(result), False)[1])

        self._executor.submit(task)

    def _toast(self, message: str) -> bool:
        self._toasts.add_toast(Adw.Toast(title=message, timeout=4))
        return False

    def _sync(self, setter: Callable[[Any], None], value: Any) -> None:
        self._syncing = True
        try:
            setter(value)
        finally:
            self._syncing = False

    # --- generic rows -----------------------------------------------------------------

    def _add_row(self, group: Adw.PreferencesGroup, item: Item) -> None:
        widget: Gtk.Widget
        if item.kind == items.RANGE and item.span:
            widget = Adw.SpinRow.new_with_range(item.span[0], item.span[1], 1)
            widget.set_title(item.label)
            widget.connect("notify::value", self._spin_changed, item)
        elif item.kind == items.TOGGLE:
            widget = Adw.SwitchRow(title=item.label)
            widget.connect("notify::active", self._switch_changed, item)
        elif item.kind == items.ENUM:
            widget = Adw.ComboRow(title=item.label, model=Gtk.StringList.new(list(item.values.values())))
            widget.connect("notify::selected", self._combo_changed, item)
            # NOTE: Left/Right step without opening the dropdown -- a popup
            # grab on a layer-shell surface can swallow the next key
            keys = Gtk.EventControllerKey(propagation_phase=Gtk.PropagationPhase.CAPTURE)
            keys.connect("key-pressed", self._combo_key, widget, item)
            widget.add_controller(keys)
        else:
            widget = Adw.ActionRow(title=item.label)
            value_label = Gtk.Label(label="…", css_classes=["dim-label"])
            widget.add_suffix(value_label)
            widget.value_label = value_label  # type: ignore[attr-defined]
        if item.note:
            widget.set_subtitle(item.note)
        widget.set_sensitive(False)
        group.add(widget)
        self._rows[item.id] = (item, widget)

    def _combo_changed(self, row: Adw.ComboRow, _pspec: Any, item: Item) -> None:
        if self._syncing:
            return
        self._enum_changed(item, list(item.values)[row.get_selected()])

    def _combo_key(
        self,
        _c: Gtk.EventControllerKey,
        keyval: int,
        _code: int,
        _mod: Gdk.ModifierType,
        row: Adw.ComboRow,
        item: Item,
    ) -> bool:
        if keyval not in (Gdk.KEY_Left, Gdk.KEY_Right):
            return False
        count = len(item.values)
        row.set_selected((row.get_selected() + (1 if keyval == Gdk.KEY_Right else -1)) % count)
        return True

    def _enum_changed(self, item: Item, value: int) -> None:
        if (source := self._pending.pop(item.id, None)) is not None:
            GLib.source_remove(source)

        def fire() -> bool:
            self._pending.pop(item.id, None)
            self._set_item(item, value)
            return False

        self._pending[item.id] = GLib.timeout_add(_DEBOUNCE_MS, fire)

    def _apply_item(self, item_id: str, reading: Reading | None) -> None:
        item, widget = self._rows[item_id]
        value = None if reading is None else reading.value
        if item.kind == items.INFO:
            widget.value_label.set_label(item.label_for(value))  # type: ignore[attr-defined]
            widget.set_sensitive(True)
            return
        if value is not None:
            if item.kind == items.RANGE:
                self._sync(widget.set_value, value)
            elif item.kind == items.TOGGLE:
                _off, on = item.values
                self._sync(widget.set_active, value == on)
            elif item.kind == items.ENUM:
                keys = list(item.values)
                if value in keys:
                    self._sync(widget.set_selected, keys.index(value))
                else:
                    widget.set_subtitle(
                        f"{item.note + ' · ' if item.note else ''}monitor reports {value:02X}"
                    )
        widget.set_sensitive(value is not None and item.writable)
        if value is not None and not item.writable:
            widget.set_sensitive(True)
            widget.set_subtitle(f"{item.label_for(value)} · {item.note or 'read-only'}")

    def _set_item(self, item: Item, value: int) -> None:
        # NOTE: on a refused write the row snaps back to what the monitor holds
        def work() -> tuple[Reading | None, str | None]:
            try:
                return self.mon.set_item(item.id, value), None
            except MonitorError as exc:
                try:
                    return self.mon.read_item(item.id), str(exc)
                except MonitorError:
                    return None, str(exc)

        def done(result: tuple[Reading | None, str | None]) -> None:
            reading, error = result
            if error:
                self._toast(error)
            self._apply_item(item.id, reading)
            if item.id == "light-mode":
                # gating of colour/position/speed changes with the mode
                self._async(lambda: self.mon.read("ambiglow"), self._on_state)

        self._async(work, done)

    def _spin_changed(self, row: Adw.SpinRow, _pspec: Any, item: Item) -> None:
        if self._syncing:
            return
        if (source := self._pending.pop(item.id, None)) is not None:
            GLib.source_remove(source)
        value = int(row.get_value())

        def fire() -> bool:
            self._pending.pop(item.id, None)
            self._set_item(item, value)
            return False

        self._pending[item.id] = GLib.timeout_add(_DEBOUNCE_MS, fire)

    def _switch_changed(self, row: Adw.SwitchRow, _pspec: Any, item: Item) -> None:
        if self._syncing:
            return
        off, on = item.values
        self._set_item(item, on if row.get_active() else off)

    # --- picture modes -----------------------------------------------------------------

    def _build_modes(self, page: Adw.PreferencesPage) -> None:
        self._modes_group = Adw.PreferencesGroup(title="Picture mode", description="SmartImage (VCP DC)")
        self._mode_rows: dict[int, Adw.ActionRow] = {}
        self._mode_buttons: dict[int | None, Gtk.CheckButton] = {}
        first: Gtk.CheckButton | None = None
        for value, label in self.mon.modes.items():
            check = Gtk.CheckButton(valign=Gtk.Align.CENTER, can_focus=False)
            if first is None:
                first = check
            else:
                check.set_group(first)
            row = Adw.ActionRow(title=label, subtitle=f"DC {value:02X}", activatable_widget=check)
            row.add_prefix(check)
            check.connect("toggled", self._mode_toggled, value)
            self._modes_group.add(row)
            self._mode_rows[value] = row
            self._mode_buttons[value] = check
        sink = Gtk.CheckButton(visible=False)
        sink.set_group(first)
        self._mode_buttons[None] = sink
        page.add(self._modes_group)

    def _mode_toggled(self, check: Gtk.CheckButton, value: int) -> None:
        if not check.get_active() or self._syncing:
            return

        # NOTE: a mode switch rewrites brightness/colour temp/RGB gains too
        # (same as the OSD), so re-read the whole section afterwards.
        def work() -> State:
            self.mon.set_mode(value)
            return self.mon.read("smartimage")

        self._async(work, self._on_state)

    # --- identity ---------------------------------------------------------------------

    def _build_identity(self, page: Adw.PreferencesPage) -> None:
        self._identity_group = Adw.PreferencesGroup(
            title="Monitor", description="from the EDID and the buses in use"
        )
        self._identity_rows: dict[str, Gtk.Label] = {}
        from evnia_panel.cli import IDENTITY_LABELS

        for key, label in IDENTITY_LABELS.items():
            row = Adw.ActionRow(title=label)
            value = Gtk.Label(label="…", css_classes=["dim-label"], selectable=True, xalign=1.0, wrap=True)
            row.add_suffix(value)
            self._identity_group.add(row)
            self._identity_rows[key] = value
        page.add(self._identity_group)
        self._async(self.mon.identity, self._on_identity)

    def _on_identity(self, facts: dict[str, str]) -> None:
        for key, label in self._identity_rows.items():
            label.set_label(facts.get(key, "n/a"))

    # --- host-side Ambiglow (USB LampArray) -------------------------------------------

    def _build_host_ambiglow(self, page: Adw.PreferencesPage) -> None:
        self._host_group = Adw.PreferencesGroup(title="Host control (USB LampArray)")
        entries = [
            (monitor.AMBIGLOW_MONITOR, "Monitor", "the effects above run"),
            (monitor.AMBIGLOW_OFF, "Off", "all lamps dark (host control)"),
            (monitor.AMBIGLOW_SOLID, "Solid colour", "last host-set colour"),
        ]
        self._host_buttons: dict[str, Gtk.CheckButton] = {}
        first: Gtk.CheckButton | None = None
        for key, title, subtitle in entries:
            check = Gtk.CheckButton(valign=Gtk.Align.CENTER, can_focus=False)
            if first is None:
                first = check
            else:
                check.set_group(first)
            row = Adw.ActionRow(title=title, subtitle=subtitle, activatable_widget=check)
            row.add_prefix(check)
            check.connect("toggled", self._host_toggled, key)
            self._host_group.add(row)
            self._host_buttons[key] = check

        palette = Gtk.FlowBox(
            selection_mode=Gtk.SelectionMode.NONE, max_children_per_line=7, homogeneous=True
        )
        for name, rgb in monitor.PALETTE.items():
            swatch = Gtk.Box(css_classes=["swatch", f"swatch-{name}"])
            button = Gtk.Button(
                child=swatch, tooltip_text=f"{name} #{monitor.format_rgb(rgb)}", has_frame=False
            )
            button.connect("clicked", lambda _b, c=rgb: self._paint(c))
            palette.append(button)
        self._custom = Gtk.ColorDialogButton(
            dialog=Gtk.ColorDialog(with_alpha=False), valign=Gtk.Align.CENTER
        )
        self._custom.connect("notify::rgba", self._custom_changed)
        row = Adw.ActionRow(title="Palette", subtitle="paints all 34 lamps; the button picks a custom RGB")
        row.add_suffix(self._custom)
        self._host_group.add(row)
        self._host_group.add(palette)
        page.add(self._host_group)

    def _host_toggled(self, check: Gtk.CheckButton, key: str) -> None:
        if not check.get_active() or self._syncing:
            return
        if key == monitor.AMBIGLOW_MONITOR:
            self._async(self.mon.ambiglow_monitor, self._on_ambiglow)
        elif key == monitor.AMBIGLOW_OFF:
            self._async(self.mon.ambiglow_off, self._on_ambiglow)
        else:
            self._paint(AmbiglowState.load().color)

    def _paint(self, rgb: tuple[int, int, int]) -> None:
        self._async(lambda: self.mon.ambiglow_solid(rgb), self._on_ambiglow)

    def _custom_changed(self, button: Gtk.ColorDialogButton, _pspec: Any) -> None:
        if self._syncing:
            return
        rgba = button.get_rgba()
        self._paint((round(rgba.red * 255), round(rgba.green * 255), round(rgba.blue * 255)))

    def _on_ambiglow(self, state: AmbiglowState) -> None:
        self._syncing = True
        try:
            self._host_buttons[state.mode].set_active(True)
            rgba = Gdk.RGBA()
            rgba.parse(f"#{monitor.format_rgb(state.color)}")
            self._custom.set_rgba(rgba)
            colour = monitor.format_rgb(state.color)
            self._host_group.set_description(
                f"last host-set: {state.mode} #{colour} (the strip cannot be read back)"
            )
        finally:
            self._syncing = False

    # --- state ------------------------------------------------------------------------

    def _on_state(self, state: State) -> None:
        mode = state.mode
        self._syncing = True
        try:
            self._mode_buttons.get(mode, self._mode_buttons[None]).set_active(True)
        finally:
            self._syncing = False
        self._modes_group.set_description(
            f"SmartImage (VCP DC) · active: {self.mon.mode_label(mode)}"
            + (f" ({mode:02X})" if mode is not None else "")
        )
        for item_id, reading in state.values.items():
            self._apply_item(item_id, reading)
        self._on_ambiglow(state.ambiglow)
        if (
            self._focus_pending
            and state.values
            and next(iter(state.values)) in (i.id for i in items.in_section("smartimage"))
        ):
            self._focus_pending = False
            self.focus_mode(mode)


class PanelApplication(Adw.Application):
    """Single-instance application; every activation after the first toggles the panel."""

    def __init__(self, mon: Monitor, daemon: bool = False) -> None:
        super().__init__(application_id=APP_ID)
        self.mon = mon
        self.daemon = daemon
        self.window: PanelWindow | None = None
        # NOTE: GApplication.run() activates the primary once; in daemon
        # mode that first activation must not show the panel
        self._skip_activation = daemon

    def do_startup(self) -> None:
        Adw.Application.do_startup(self)
        css = Gtk.CssProvider()
        css.load_from_string(_CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        if self.daemon:
            # NOTE: hold() keeps the main loop alive with no visible window
            self.hold()
            self.window = PanelWindow(self, self.mon)

    def do_activate(self) -> None:
        log.debug("activate (daemon=%s, window=%s)", self.daemon, self.window is not None)
        if self._skip_activation:
            self._skip_activation = False
            return
        if self.window is None:
            self.window = PanelWindow(self, self.mon)
        elif self.window.get_visible():
            self.window.dismiss()
            return
        elif not self.daemon:
            self.quit()
            return
        self.window.summon()


def run(mon: Monitor | None = None, daemon: bool = False) -> int:
    """Run the panel.

    Args:
        mon: Monitor facade; a default one is created when ``None``.
        daemon: Stay resident with the window hidden between activations.

    Returns:
        The GApplication exit status.
    """
    app = PanelApplication(mon or Monitor(), daemon=daemon)
    # NOTE: GApplication parses argv itself; the CLI already did
    return app.run(None)
