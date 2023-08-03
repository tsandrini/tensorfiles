# --- modules/services/x11/window-managers/xmonad/default.nix
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
{ config, lib, pkgs, inputs, system, ... }:
with builtins;
with lib;
let
  cfg = config.tensorfiles.services.x11.window-managers.xmonad;
  _ = mkOverride 500;
  persistenceCheck = (cfg.persistence)
    && (config ? tensorfiles.system.persistence)
    && (config.tensorfiles.system.persistence.enable);
in {
  options.tensorfiles.services.x11.window-managers.xmonad = with types; {
    enable = mkEnableOption (mdDoc ''
      Module predefining & setting up agenix for handling secrets
    '');

    persistence = mkEnableOption (mdDoc ''
      Whether to autoappend files/folders to the persistence system.
      Note that this will get executed only if

      1. persistence = true;
      2. tensorfiles.system.persistence module is loaded
      3. tensorfiles.system.persistence.enable = true;
    '') // {
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      #
      #
    })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
