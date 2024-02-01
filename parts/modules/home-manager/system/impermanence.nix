# --- parts/modules/home-manager/system/impermanence.nix
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
  localFlake,
  inputs,
}: {
  config,
  lib,
  ...
}:
with builtins;
with lib; let
  # inherit (localFlake.lib) mkOverrideAtHmModuleLevel;
  cfg = config.tensorfiles.hm.system.impermanence;
  # _ = mkOverrideAtHmModuleLevel;
in {
  options.tensorfiles.hm.system.impermanence = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    persistentRoot = mkOption {
      type = path;
      default = "/persist";
      description = mdDoc ''
        Path on the already mounted filesystem for the persistent root, that is,
        a root where we should store the persistent files and against which should
        we link the temporary files against.

        This is usually simply just /persist.
      '';
    };

    allowOther = mkOption {
      type = bool;
      default = false;
      description = mdDoc ''
        TODO
      '';
    };
  };

  imports = with inputs; [impermanence.nixosModules.home-manager.impermanence];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      assertions = [
        {
          assertion = hasAttr "impermanence" inputs;
          message = "Impermanence flake missing in the inputs library. Please add it to your flake inputs.";
        }
      ];
    }
    # |----------------------------------------------------------------------| #
    {
      home.persistence."${cfg.persistentRoot}" = {
        inherit (cfg) allowOther;
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
