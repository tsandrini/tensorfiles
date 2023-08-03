# --- modules/services/networking/networkmanager.nix
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
{ config, lib, pkgs, ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel isPersistenceEnabled;

  cfg = config.tensorfiles.services.networking.networkmanager;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.services.networking.networkmanager = with types;
    with tensorfiles.options; {

      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the networkmanager service.
      '');

      persistence = { enable = mkPersistenceEnableOption; };

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: {

          addUserToGroup = mkOption {
            type = bool;
            default = true;
            description = mdDoc ''
              Whether the given user should be added to the
              `networkmanager` group.
            '';
          };
        });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({ networking.networkmanager.enable = _ true; })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.persistence.enable && (isPersistenceEnabled config))
      (let persistence = config.tensorfiles.system.persistence;
      in {
        environment.persistence."${persistence.persistentRoot}" = {
          directories = [ "/etc/NetworkManager/system-connections" ];
          files = [
            "/var/lib/NetworkManager/secret_key" # TODO probably move elsewhere?
            "/var/lib/NetworkManager/seen-bssids"
            "/var/lib/NetworkManager/timestamps"
          ];
        };
      }))
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      users.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in { extraGroups = optional userCfg.addUserToGroup "networkmanager"; });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
