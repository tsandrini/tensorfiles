# --- modules/security/agenix.nix
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
  cfg = config.tensorfiles.security.agenix;
  _ = mkOverride 500;
in {
  # TODO conditional persistence
  options.tensorfiles.security.agenix = with types; {
    enable = mkEnableOption (mdDoc ''
      Module predefining & setting up agenix for handling secrets
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      assertions = [
        {
          assertion = hasAttr "age" config;
          message =
            "age attribute missing, please install and import the agenix module";
        }
        {
          assertion = hasAttr "agenix" inputs;
          message =
            "inputs.agenix attribute missing, please import agenix in such a way so it's accessible via the inputs attribute";
        }
      ];
    })
    ({
      environment.systemPackages = with pkgs; [
        inputs.agenix.packages.${system}.default
        age
      ];
      age.identityPaths =
        [ "/persist/root/.ssh/id_ed25519" "/root/.ssh/id_ed25519" ];
    })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}