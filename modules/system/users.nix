# --- modules/system/users.nix
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
{ config, lib, pkgs, inputs, user ? "root", ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules)
    mkOverrideAtModuleLevel isPersistenceEnabled isAgenixEnabled;
  inherit (tensorfiles.attrsets) mapToAttrsAndMerge;

  cfg = config.tensorfiles.system.users;
  _ = mkOverrideAtModuleLevel;
in {
  # TODO move bluetooth dir to hardware
  # TODO pass also root user
  # TODO move .gpg and .ssh to ssh-agent? or not?
  # TODO zotero
  # TODO move fontconfig elsewhere
  options.tensorfiles.system.users = with types;
    with tensorfiles.options; {
      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that sets up the basis for the userspace, that is
        declarative management, basis for the home directories and also
        configures home-manager, persistence, agenix if they are enabled.

        (Persistence) The users module will automatically append and set up the
        usual home related directories, however, in case that you have an opt-in
        filesystem with a persistent home, you should set
        `persistence.enable = false`

        (Agenix) This module uses the following secrets
        1. `common/passwords/users/$user_default`
          User passwords. They are meant to be defaults that should be later
          configured and changed appropriately on each host, which would ideally be
          `hosts/$host/passwords/users/$user`
      '');

      persistence = { enable = mkPersistenceEnableOption; };

      agenix = { enable = mkAgenixEnableOption; };

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption {

          isSudoer = mkOption {
            type = bool;
            default = true;
            description = mdDoc ''
              Add user to sudoers (ie the `wheel` group)
            '';
          };

          downloadsDir = mkOption {
            type = nullOr str;
            default = "Downloads";
            description = mdDoc ''
              The usual downloads home dir.
              Path is relative to the given user home directory.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.downloadsDir = null;`
            '';
          };

          orgDir = mkOption {
            type = nullOr str;
            default = "OrgBundle";
            description = mdDoc ''
              Central directory for the organization of your whole life!
              Org-mode, org-roam, org-agenda, and much more!
              Path is relative to the given user home directory.

              If you'd like to disable the features of the org dir, just
              set it to null, ie `home.settings.$user.orgDir = null;`
            '';
          };

          projectsDir = mkOption {
            type = nullOr str;
            default = "ProjectBundle";
            description = mdDoc ''
              TODO
              Path is relative to the given user home directory.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.projectsDir = null;`
            '';
          };

          miscDataDir = mkOption {
            type = nullOr str;
            default = "FiberBundle";
            description = mdDoc ''
              TODO
              Path is relative to the given user home directory.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.miscDataDir = null;`
            '';
          };
        };
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    ({
      assertions = with tensorfiles.asserts;
        [ (mkIf cfg.home.enable (assertHomeManagerLoaded config)) ];
    })
    # |----------------------------------------------------------------------| #
    ({ users.mutableUsers = _ false; })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.useGlobalPkgs = _ true;
      home-manager.useUserPackages = _ true;
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          home = {
            username = _ "${_user}";
            homeDirectory = _ "/home/${_user}";
            stateVersion = _ "23.05";
          };
          fonts.fontconfig.enable = _ true;
        });
    })
    # |----------------------------------------------------------------------| #
    # TODO TODO TODO TODO
    (mkIf cfg.home.enable {
      users.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          isNormalUser = _ (_user != "root");
          isSystemUser = _ (_user == "root");
          extraGroups = [ "video" "audio" "camera" ]
            ++ (optional userCfg.isSudoer "wheel");
          home = (if _user != "root" then "/home/${_user}" else "/root");

          passwordFile = (mkIf (isAgenixEnabled config) (_
            config.age.secrets."common/passwords/users/${_user}_default".path));
        });
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.home.enable && (isAgenixEnabled config)) {
      age.secrets = mapToAttrsAndMerge (attrNames cfg.home.settings) (_user: {
        "common/passwords/users/${_user}_default" = {
          file = _ ../../secrets/common/passwords/users/${_user}_default.age;
        };
      });
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.home.enable && (isPersistenceEnabled config))
      (let persistence = config.tensorfiles.system.persistence;
      in {
        environment.persistence."${persistence.persistentRoot}".users =
          genAttrs (attrNames cfg.home.settings) (_user:
            let userCfg = cfg.home.settings."${_user}";
            in {
              # settings this to `config.users.users.${_user}.home;`
              # unfortunetaly results in infinite recursion
              home = (if _user != "root" then "/home/${_user}" else "/root");
              directories = [
                {
                  directory = ".gnupg";
                  mode = "0700";
                }
                {
                  directory = ".ssh";
                  mode = "0700";
                }
              ] ++ (optional (userCfg.downloadsDir != null)
                userCfg.downloadsDir)
                ++ (optional (userCfg.orgDir != null) userCfg.orgDir)
                ++ (optional (userCfg.projectsDir != null) userCfg.projectsDir)
                ++ (optional (userCfg.miscDataDir != null) userCfg.miscDataDir);
            });
      }))
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
