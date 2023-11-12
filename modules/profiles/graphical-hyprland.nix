# --- modules/profiles/graphical-hyprland.nix
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
{
  config,
  lib,
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.graphical-hyprland;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.profiles.graphical-hyprland = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the laptop system profile.

      **TODO**: decouple this into a graphical + xmonad + persitence profiles
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.headless.enable = _ true;

        misc.gtk.enable = _ true;

        programs = {
          newsboat.enable = _ true;
          # dmenu.enable = _ true;
          file-managers.lf.enable = _ true;
          pywal.enable = _ true;
          terminals.kitty.enable = _ true;
          # terminals.alacritty.enable = _ true;
          browsers.firefox.enable = _ true;
        };

        services = {
          dunst.enable = _ true;
          pywalfox-native.enable = _ true;
          wayland.window-managers.hyprland.enable = _ true;
        };

        system.persistence = {
          enable = _ true;
          btrfsWipe = {
            enable = _ true;
            rootPartition = _ "/dev/mapper/enc";
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
