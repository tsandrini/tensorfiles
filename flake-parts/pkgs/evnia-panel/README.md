# evnia-panel

A scratchpad-style control panel for the Philips Evnia 32M2N8900P OLED
monitor, so the one OSD button can stay untouched. One keybind opens a
keyboard-driven overlay centred on the Evnia whose pages mirror the
monitor's own menu; `Esc` (or the same keybind) closes it. The same code is
a CLI for scripting.

Everything is measured, nothing is guessed: the menu table
(`items.py`) is the allow-list. Only the codes and values measured on the
real monitor (`desktop-build/research/`) are ever written, and after every
write the panel shows the read-back, never the requested value.

## Backends

- DDC/CI, spoken directly on the DisplayPort AUX I²C bus (`ddc.py`). Both
  the standard MCCS codes and Philips' vendor sub-features (`E2 A0xx`,
  which need an extended VCP packet no stock tool sends) go through it; a
  request costs ~30 ms. The monitor is found by model string: the DRM
  connector whose EDID carries `32M2N8900P` names its AUX bus as an `i2c-N`
  child in sysfs.
- Ambiglow host control: USB HID LampArray (`0cf2:b217`, `/dev/hidraw*`),
  raw `HIDIOCSFEATURE`/`HIDIOCGFEATURE` ioctls (`lamparray.py`).

## Pages (native menu order)

1. **SmartImage** — picture mode (`DC`, editable mode map from
   `$XDG_CONFIG_HOME/evnia-panel/modes.json`), brightness, contrast, gamma,
   colour temperature, sharpness, RGB gains.
2. **GameMode** — Adaptive Sync (read-only over DDC), crosshair, Stark
   ShadowBoost, Smart Sniper size (re-syncs the link, ~1 s black) and
   position.
3. **Ambiglow** — the monitor's own effects (on/off, light mode, colour,
   position, brightness, speed; colour/position/speed are refused by the
   firmware in Follow Video) plus host control through the LampArray: hand
   back / all off / solid colour with the OSD palette or a custom RGB.
4. **Input** — input source.
5. **Audio** — volume, mute.
6. **System** — OSD position/transparency/time-out, Smart Size, USB standby,
   KVM (read-only), over scan.
7. **OLED care** — screen saver, pixel orbiting (firmware refuses changes),
   auto pixel refresh, UniBright, multi logo protection, boundary and
   taskbar dimmers, thermal protection.
8. **Info** — identity from the EDID (model, serial, manufacturer, build
   date), connector, DDC bus, the LampArray (node, lamp count, strip size),
   firmware and MCCS versions, and the OLED counters (hours, hours since
   pixel refresh, refresh count, two temperature-like sensors).

Every non-obvious row carries a one-line description.

Not reachable (OSD only, measured): PIP/PBP, audio mode and EQ, Power LED,
resolution notice, HDR picture modes, factory reset, manual pixel refresh.

## Summoning

The application is unique per session (GApplication over DBus); every
activation after the first toggles the panel. A cold start is ~500 ms
(Python + GTK), so the HM module runs `evnia-panel --daemon` as a user
service: the window is built once at login and only shown/hidden on each
summon. The keybind runs `evnia-panel-toggle`, a shell script that calls
`org.gtk.Application.Activate` through `gdbus` (one round trip) and falls
back to a plain launch when no daemon runs. niri only gives exclusive
layer-shell focus to surfaces on the focused output, so the panel focuses
the Evnia's output on summon and restores the previous one on dismiss. The
state is re-read on every show, section by section.

## CLI

```text
evnia-panel                          # the panel (toggle)
evnia-panel --daemon                 # resident mode, used by the user service
evnia-panel-toggle                   # cheap summoner for keybinds
evnia-panel get [--json] [--section oled]
evnia-panel items                    # every item with its allowed values
evnia-panel info                     # EDID identity, buses, counters, versions
evnia-panel set light-mode "color wave"
evnia-panel set crosshair on | set boundary-dimmer 2 | set brightness 60
evnia-panel mode economy             # picture mode by label or hex
evnia-panel power on | off           # D6; `on` wakes the panel from standby
evnia-panel ambiglow monitor | off | solid azure | solid ff8800
evnia-panel raw 86 | raw --sub 4e    # read one code / sub-feature (research)
```

Exit status: 0, 2 on a usage error or when the monitor refused (the
read-back differs) or failed.

## Permissions

- `/dev/i2c-*`: `hardware.i2c.enable` (uaccess for the seat user).
- `/dev/hidraw*` of `0cf2:b217`: the package ships
  `lib/udev/rules.d/70-evnia-panel.rules` (`TAG+="uaccess"`); add the
  package to `services.udev.packages` on the host.

## Layout

```text
src/evnia_panel/
  ddc.py        raw DDC/CI transport (standard + E2 sub-features), bus lookup
  items.py      the menu as data = the allow-list
  lamparray.py  HID LampArray reports and ioctls
  monitor.py    facade: mode map, reads/writes with read-back, host Ambiglow
  cli.py        argparse front-end generated from the table
  ui.py         GTK4/libadwaita/gtk4-layer-shell panel generated from the table
bin/evnia-panel-toggle   gdbus summoner (generated by default.nix)
lib/udev/rules.d/70-evnia-panel.rules
```
