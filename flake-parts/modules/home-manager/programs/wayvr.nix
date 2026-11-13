# --- flake-parts/modules/home-manager/programs/wayvr.nix
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
{ localFlake }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkPackageOption
    types
    literalExpression
    concatStrings
    mapAttrsToList
    escapeShellArg
    ;
  inherit (localFlake.lib.modules) isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.wayvr;

  niriCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake";
  scaled = cfg.outputScales != { };

  setScale = output: scale: ''
    if cur=$(niri msg --json outputs | jq -er --arg o ${escapeShellArg output} '.[$o].logical.scale'); then
      prev[${escapeShellArg output}]=$cur
      niri msg output ${escapeShellArg output} scale ${builtins.toJSON scale}
    fi
  '';

  launcher = pkgs.writeShellApplication {
    name = "wayvr-session";
    runtimeInputs = [
      config.tensorfiles.hm.programs.niri-flake.package
      pkgs.jq
      cfg.package
    ];
    text = ''
      declare -A prev=()
      restore() {
        for output in "''${!prev[@]}"; do
          niri msg output "$output" scale "''${prev[$output]}" || true
        done
      }
      trap restore EXIT

      # NOTE: before WayVR starts, it breaks on output changes while running
      ${concatStrings (mapAttrsToList setScale cfg.outputScales)}
      if [ "''${#prev[@]}" -gt 0 ]; then sleep 1; fi

      wayvr "$@"
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "wayvr-session";
    desktopName = "WayVR";
    comment = "Desktop in VR, with the outputs rescaled while it runs";
    exec = "wayvr-session";
    icon = "wayvr";
    categories = [
      "Utility"
      "X-WiVRn-VR"
    ];
    # NOTE: WiVRn's launcher ignores NoDisplay; hides it from desktop menus only
    noDisplay = true;
  };

  # upstream's entry swapped for the wrapper's, so launchers list WayVR once
  scaledPackage = pkgs.symlinkJoin {
    name = "wayvr-session";
    paths = [
      cfg.package
      launcher
      desktopItem
    ];
    postBuild = ''
      rm "$out/share/applications/wayvr.desktop"
    '';
  };
in
{
  options.tensorfiles.hm.programs.wayvr = {
    enable = mkEnableOption ''
      Installs WayVR, which shows the Wayland desktop (screens, windows, a
      keyboard) inside VR on top of any OpenXR runtime. Its desktop entry
      carries `X-WiVRn-VR`, so it is listed in the WiVRn headset launcher
      (see `tensorfiles.services.wivrn`).

      WayVR keeps its own settings (pointer, capture, layout) in
      `$XDG_CONFIG_HOME/wayvr/conf.d/zz-saved-config.json5` and rewrites the
      file itself, so they are left to its settings panel.
    '';

    package = mkPackageOption pkgs "wayvr" { };

    outputScales = mkOption {
      type = types.attrsOf types.numbers.positive;
      default = { };
      example = literalExpression ''{ "DP-1" = 1.5; }'';
      description = ''
        niri output scales to apply while WayVR runs, by connector name. A
        desktop that is readable on a monitor tends to be far too dense for
        a headset's pixels, and WayVR can't follow output changes made while
        it runs, so the launcher sets these before it starts and restores the
        previous scales when it exits. Outputs that aren't connected are
        skipped. Requires `tensorfiles.hm.programs.niri-flake`; when empty,
        upstream's plain launcher entry is installed instead.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !scaled || niriCheck;
        message = "tensorfiles.hm.programs.wayvr.outputScales rescales through niri and needs tensorfiles.hm.programs.niri-flake.";
      }
    ];

    home.packages = [ (if scaled then scaledPackage else cfg.package) ];
  };

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
