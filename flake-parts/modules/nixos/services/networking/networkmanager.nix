# --- flake-parts/modules/nixos/services/networking/networkmanager.nix
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
{ localFlake }:
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkImpermanenceEnableOption;

  cfg = config.tensorfiles.services.networking.networkmanager;
  _ = mkOverrideAtModuleLevel;

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.system.impermanence") && cfg.impermanence.enable;
  impermanence = if impermanenceCheck then config.tensorfiles.system.impermanence else { };
in
{
  options.tensorfiles.services.networking.networkmanager = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the networkmanager service.
    '';

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    { networking.networkmanager.enable = _ true; }
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      environment.persistence."${impermanence.persistentRoot}" = {
        directories = [ "/etc/NetworkManager/system-connections" ];
        files = [
          "/var/lib/NetworkManager/secret_key" # TODO probably move elsewhere?
          "/var/lib/NetworkManager/seen-bssids"
          "/var/lib/NetworkManager/timestamps"
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
