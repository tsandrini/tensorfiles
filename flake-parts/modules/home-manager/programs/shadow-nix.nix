# --- flake-parts/modules/home-manager/programs/shadow-nix.nix
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
{ localFlake, inputs }:
{ config, lib, ... }:
with builtins;
with lib;
let
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.shadow-nix;
  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.shadow-nix = with types; {
    enable = mkEnableOption ''
      TODO
    '';
  };

  imports = [ (inputs.shadow-nix + "/import/home-manager.nix") ];

  # The shadow module is unfortunately import by default, so we have to explicitly
  # disable it
  config = mkIf true (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.shadow-client = {
        enable = _ cfg.enable;
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}