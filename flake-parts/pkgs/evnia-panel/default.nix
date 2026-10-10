# --- flake-parts/pkgs/evnia-panel/default.nix
#
# Author:  tsandrini <t@tsandrini.sh>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{
  lib,
  buildPythonApplication,
  setuptools,
  pytestCheckHook,
  pygobject3,
  gobject-introspection,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  gtk4-layer-shell,
  adwaita-icon-theme,
  glib,
  runtimeShell,
}:
buildPythonApplication {
  pname = "evnia-panel";
  version = "0.2.0";
  pyproject = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./README.md
      ./src
      ./tests
    ];
  };

  build-system = [ setuptools ];

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    gtk4-layer-shell
    adwaita-icon-theme # NOTE: section icons; wrapGAppsHook4 puts it on XDG_DATA_DIRS
  ];

  dependencies = [ pygobject3 ];

  # NOTE: wrapGAppsHook4 + buildPythonApplication both wrap; let the python
  # wrapper carry the gapps args instead of double-wrapping
  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
      --set EVNIA_PANEL_LAYER_SHELL ${gtk4-layer-shell}/lib/libgtk4-layer-shell.so.0
    )
  '';

  postInstall = ''
    # Cheap summoner for keybinds: one DBus round trip when the daemon runs
    # (org.gtk.Application.Activate toggles the panel), plain launch otherwise.
    cat > $out/bin/evnia-panel-toggle <<EOF
    #!${runtimeShell}
    ${glib.bin}/bin/gdbus call --session --dest sh.tsandrini.EvniaPanel --object-path /sh/tsandrini/EvniaPanel --method org.gtk.Application.Activate '{}' >/dev/null 2>&1 || exec $out/bin/evnia-panel panel
    EOF
    chmod +x $out/bin/evnia-panel-toggle

    mkdir -p $out/lib/udev/rules.d
    # Ambiglow LampArray: seat user may open the hidraw node. Must sort
    # before 73-seat-late.rules for TAG+="uaccess" to take effect.
    cat > $out/lib/udev/rules.d/70-evnia-panel.rules <<'RULES'
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0cf2", ATTRS{idProduct}=="b217", TAG+="uaccess"
    RULES
  '';

  nativeCheckInputs = [ pytestCheckHook ];
  pythonImportsCheck = [
    "evnia_panel"
    "evnia_panel.ddc"
    "evnia_panel.items"
    "evnia_panel.lamparray"
    "evnia_panel.monitor"
    "evnia_panel.cli"
  ];

  meta = {
    description = "Keyboard-driven overlay panel and CLI for the Philips Evnia 32M2N8900P (raw DDC/CI incl. vendor sub-features + USB Ambiglow)";
    license = lib.licenses.mit;
    mainProgram = "evnia-panel";
    platforms = lib.platforms.linux;
  };
}
