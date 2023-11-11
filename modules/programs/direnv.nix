# --- modules/programs/direnv.nix
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
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;
  inherit (tensorfiles.nixos) getUserShell;

  cfg = config.tensorfiles.programs.direnv;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.programs.direnv = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles direnv colorscheme generator.
    '');

    persistence = {enable = mkPersistenceEnableOption;};

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        pkg = mkOption {
          type = package;
          default = pkgs.direnv;
          description = mdDoc ''
            Which package to use for the direnv utilities. You can provide any
            custom derivation or forks with differing internals as long
            as the API and binaries stay the same and reside at the
            same place.
          '';
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
        userShell = getUserShell {
          inherit _user;
          cfg = config;
        };
      in {
        programs.direnv = {
          enable = _ true;
          package = _ userCfg.pkg;
          enableBashIntegration = _ (userShell == "bash");
          enableFishIntegration = _ (userShell == "fish");
          enableNushellIntegration = _ (userShell == "nu");
          enableZshIntegration = _ (userShell == "zsh");
          nix-direnv.enable = _ true;
        };
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
