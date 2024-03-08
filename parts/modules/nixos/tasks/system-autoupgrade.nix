# --- parts/modules/nixos/tasks/system-autoupgrade.nix
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
  hostName,
  ...
}:
with builtins;
with lib; let
  inherit (localFlake.lib) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.tasks.system-autoupgrade;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.tasks.system-autoupgrade = with types; {
    enable = mkEnableOption (mdDoc ''
      Module enabling system wide nixpkgs & host autoupgrade
      Enables NixOS module that configures the task handling periodix nixpkgs
      and host autoupgrades.
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      system.autoUpgrade = {
        enable = _ false;
        flake = _ "github:tsandrini/tensorfiles#${config.networking.hostName}";
        # channel = _ "https://nixos.org/channels/nixos-unstable";
        allowReboot = _ true;
        randomizedDelaySec = _ "5m";
        rebootWindow = {
          lower = _ "02:00";
          upper = _ "05:00";
        };
        flags = [
          "--impure"
          "--accept-flake-config"
        ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
