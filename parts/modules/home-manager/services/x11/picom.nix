# --- parts/modules/home-manager/services/x11/picom.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
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
{localFlake}: {
  config,
  lib,
  ...
}:
with builtins;
with lib; let
  inherit (localFlake.lib) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.services.x11.picom;
  _ = mkOverrideAtHmModuleLevel;
in {
  options.tensorfiles.hm.services.x11.picom = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.picom = {
        enable = _ true;
        # backend = _ "glx";
        activeOpacity = _ 1.0;
        fade = _ true;
        fadeDelta = _ 4;
        fadeSteps = _ [3.0e-2 3.0e-2];
        inactiveOpacity = _ 1.0;
        shadow = _ true;
        shadowOffsets = _ [(-5) (-5)];
        shadowOpacity = _ 0.5;
        vSync = _ true;
        shadowExclude = _ [
          "! name~=''"
          "name = 'Notification'"
          "name = 'Plank'"
          "name = 'Docky'"
          "name = 'Kupfer'"
          "name = 'xfce4-notifyd'"
          "name = 'cpt_frame_window'"
          "name *= 'VLC'"
          "name *= 'compton'"
          "name *= 'picom'"
          "name *= 'Chromium'"
          "name *= 'Chrome'"
          "class_g = 'Firefox' && argb"
          "class_g = 'Conky'"
          "class_g = 'Kupfer'"
          "class_g = 'Synapse'"
          "class_g ?= 'Notify-osd'"
          "class_g ?= 'Cairo-dock'"
          "class_g ?= 'Xfce4-notifyd'"
          "class_g ?= 'Xfce4-power-manager'"
          "_GTK_FRAME_EXTENTS@:c"
          "_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
        ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
