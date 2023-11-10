# --- modules/profiles/base.nix
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
{ config, lib, ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.base;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.profiles.base = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the base system profile.

        **Base layer** sets up necessary structures to be able to simply
        just evaluate the configuration, ie. not build it, meaning that this layer
        enables fundamental functionality that other higher level modules rely
        on.
      '');
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      system.stateVersion = _ "23.05";

      tensorfiles = {
        system.users.enable = _ true;
        misc.nix.enable = _ true;
        misc.xdg.enable = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
