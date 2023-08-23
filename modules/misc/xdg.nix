# --- modules/misc/xdg.nix
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
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;
  inherit (tensorfiles.nixos)
    isUsersSystemEnabled getUserHomeDir getUserConfigDir getUserCacheDir
    getUserAppDataDir getUserAppStateDir;

  cfg = config.tensorfiles.misc.xdg;
  _ = mkOverrideAtModuleLevel;
in {
  # TODO add non-hm nixos only based configuration
  options.tensorfiles.misc.xdg = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the xdg toolset.
      '');

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: { });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      assertions = with tensorfiles.asserts;
        [ (mkIf cfg.home.enable (assertHomeManagerLoaded config)) ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let
          args = {
            inherit _user;
            cfg = config;
          };
        in {
          xdg = {
            enable = _ true;
            configHome = _ (getUserConfigDir args);
            cacheHome = _ (getUserCacheDir args);
            dataHome = _ (getUserAppDataDir args);
            stateHome = _ (getUserAppStateDir args);

            mime.enable = _ true;
            mimeApps = { enable = _ true; };
          };
        });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
