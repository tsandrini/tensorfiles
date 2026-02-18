# --- flake-parts/modules/home-manager/programs/dank-material-shell.nix
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
{ localFlake, inputs }:
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;
  inherit (localFlake.lib.modules) isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.programs.dank-material-shell;
  _ = mkOverrideAtHmModuleLevel;

  pywalCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable;
  niri-flakeCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake") && cfg.niri-flake.enable;
in
{
  options.tensorfiles.hm.programs.dank-material-shell = {
    enable = mkEnableOption ''

    '';

    niri-flake = {
      enable = mkEnableOption "Enables binding for the niri-flake project";
    };

    pywal = {
      enable = mkPywalEnableOption;
    };
  };

  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri # TODO No better place to have this unfortunately
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.dank-material-shell = {
        enable = _ true;
        systemd = {
          enable = _ (!niri-flakeCheck);
          restartIfChanged = _ true;
        };

        enableSystemMonitoring = _ true;
        enableVPN = _ true;
        enableDynamicTheming = _ true;
        enableAudioWavelength = _ true;
        enableCalendarEvents = _ true;
        enableClipboardPaste = _ true;
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf pywalCheck {
      systemd.user.tmpfiles.rules = [
        "d ${config.xdg.cacheHome}/wal 0700 - - -"
        "L+ ${config.xdg.cacheHome}/wal/colors.json - - - - ${config.xdg.cacheHome}/wal/dank-pywalfox.json"
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf niri-flakeCheck {
      programs.dank-material-shell.niri = {
        enableSpawn = _ true;
        enableKeybinds = _ false;
        includes = {
          enable = _ true;
          override = _ true;
          filesToInclude = [
            "alttab"
            "binds"
            "cursor"
            "colors"
            "layout"
            "outputs"
            "wpblur"
          ];
        };
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
