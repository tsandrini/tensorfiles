# --- modules/programs/pywal.nix
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
  inherit
    (tensorfiles.nixos)
    isPersistenceEnabled
    getUserHomeDir
    getUserCacheDir
    getUserConfigDir
    ;

  cfg = config.tensorfiles.programs.pywal;
in {
  options.tensorfiles.programs.pywal = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles pywal colorscheme generator.
    '');

    persistence = {enable = mkPersistenceEnableOption;};

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        pkg = mkOption {
          type = package;
          default = pkgs.pywal;
          description = mdDoc ''
            Which package to use for the pywal utilities. You can provide any
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
        homeDir = getUserHomeDir {
          inherit _user;
          cfg = config;
        };
        cacheDir = getUserCacheDir {
          inherit _user;
          cfg = config;
        };
        configDir = getUserConfigDir {
          inherit _user;
          cfg = config;
        };
      in {
        home.packages = with pkgs; [userCfg.pkg];

        systemd.user.tmpfiles.rules = ["L ${homeDir}/.Xresources - - - - ${cacheDir}/wal/Xresources"];
        home.file."${configDir}/wal/templates/Xresources".text = mkBefore ''
          ! Xft.autohint: 0
          ! Xft*antialias: true
          ! Xft.hinting: true
          ! Xft.hintstyle: hintslight
          ! Xft*dpi: 96
          ! Xft.lcdfilter: lcddefault

          *.background: {background}
          *.foreground: {foreground}
          *.cursorColor: {cursor}

          ! Colors 0-15.
          *.color0: {color0}
          *color0:  {color0}
          *.color1: {color1}
          *color1:  {color1}
          *.color2: {color2}
          *color2:  {color2}
          *.color3: {color3}
          *color3:  {color3}
          *.color4: {color4}
          *color4:  {color4}
          *.color5: {color5}
          *color5:  {color5}
          *.color6: {color6}
          *color6:  {color6}
          *.color7: {color7}
          *color7:  {color7}
          *.color8: {color8}
          *color8:  {color8}
          *.color9: {color9}
          *color9:  {color9}
          *.color10: {color10}
          *color10:  {color10}
          *.color11: {color11}
          *color11:  {color11}
          *.color12: {color12}
          *color12:  {color12}
          *.color13: {color13}
          *color13:  {color13}
          *.color14: {color14}
          *color14:  {color14}
          *.color15: {color15}
          *color15:  {color15}
        '';
      });
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.home.enable && (isPersistenceEnabled config))
      (let
        inherit (config.tensorfiles.system) persistence;
      in {
        environment.persistence."${persistence.persistentRoot}".users = genAttrs (attrNames cfg.home.settings) (_user: {
          files = [".fehbg"];
          # not needed anymore
          # directories = [ (toRelative (cacheDir + "/wal")) ];
        });
      }))
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
