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
  inherit (tensorfiles.types) email;
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;
  inherit (tensorfiles.nixos)
    isPersistenceEnabled isAgenixEnabled absolutePathToRelativeHome;
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

        settings = mkHomeSettingsOption (_user: {

          isSudoer = mkOption {
            type = bool;
            default = true;
            description = mdDoc ''
              Add user to sudoers (ie the `wheel` group)
            '';
          };

          initDirectoryStructure = mkOption {
            type = bool;
            default = true;
            description = mdDoc ''
              Whether to automatically create all the directories. Home-manager
              doesn't do this automatically unless you need to populate it with
              files, so this option might be useful.

              This is achieved by creating an empty `.blank` file inside the
              directories, thanks to this we preserve the overall purity.
            '';
          };

          email = mkOption {
            type = nullOr email;
            default = null;
            description = mdDoc ''
              TODO
            '';
          };

          description = mkOption {
            type = nullOr str;
            default = null;
            description = mdDoc ''
              TODO
            '';
          };

          homeDir = mkOption {
            type = path;
            default = (if _user != "root" then "/home/${_user}" else "/root");
            description = mdDoc ''
              TODO
            '';
          };

          configDir = mkOption {
            type = path;
            default = (if _user != "root" then
              "/home/${_user}/.config"
            else
              "/root/.config");
            description = mdDoc ''
              The usual downloads home dir.
              Path is relative to the given user home directory.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.downloadsDir = null;`
            '';
          };

          cacheDir = mkOption {
            type = path;
            default = (if _user != "root" then
              "/home/${_user}/.cache"
            else
              "/root/.cache");
            description = mdDoc ''
              TODO
            '';
          };

          appDataDir = mkOption {
            type = path;
            default = (if _user != "root" then
              "/home/${_user}/.local/share"
            else
              "/root/.local/share");
            description = mdDoc ''
              The usual downloads home dir.
              Path is relative to the given user home directory.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.downloadsDir = null;`
            '';
          };

          appStateDir = mkOption {
            type = path;
            default = (if _user != "root" then
              "/home/${_user}/.local/state"
            else
              "/root/.local/state");
            description = mdDoc ''
              TODO
            '';
          };

          downloadsDir = mkOption {
            type = nullOr path;
            default = (if _user != "root" then
              "/home/${_user}/Downloads"
            else
              "/root/Downloads");
            description = mdDoc ''
              The usual downloads home dir.

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.downloadsDir = null;`
            '';
          };

          orgDir = mkOption {
            type = nullOr path;
            default = (if _user != "root" then
              "/home/${_user}/OrgBundle"
            else
              "/root/OrgBundle");
            description = mdDoc ''
              Central directory for the organization of your whole life!
              Org-mode, org-roam, org-agenda, and much more!

              If you'd like to disable the features of the org dir, just
              set it to null, ie `home.settings.$user.orgDir = null;`
            '';
          };

          projectsDir = mkOption {
            type = nullOr path;
            default = (if _user != "root" then
              "/home/${_user}/ProjectBundle"
            else
              "/root/ProjectBundle");
            description = mdDoc ''
              TODO

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.projectsDir = null;`
            '';
          };

          miscDataDir = mkOption {
            type = nullOr path;
            default = (if _user != "root" then
              "/home/${_user}/FiberBundle"
            else
              "/root/FiberBundle");
            description = mdDoc ''
              TODO

              If you'd like to disable the features of the downloads dir, just
              set it to null, ie `home.settings.$user.miscDataDir = null;`
            '';
          };
        });
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
            homeDirectory = _ userCfg.homeDir;
            stateVersion = _ "23.05";
          };

          fonts.fontconfig.enable = _ true;

          home.file = mkIf userCfg.initDirectoryStructure {
            "${userCfg.configDir}/.blank".text = mkBefore "";
            "${userCfg.cacheDir}/.blank".text = mkBefore "";
            "${userCfg.appDataDir}/.blank".text = mkBefore "";
            "${userCfg.appStateDir}/.blank".text = mkBefore "";

            "${userCfg.downloadsDir}/.blank".text =
              mkIf (userCfg.downloadsDir != null) (mkBefore "");
            "${userCfg.orgDir}/.blank".text =
              mkIf (userCfg.orgDir != null) (mkBefore "");
            "${userCfg.projectsDir}/.blank".text =
              mkIf (userCfg.projectsDir != null) (mkBefore "");
            "${userCfg.miscDataDir}/.blank".text =
              mkIf (userCfg.miscDataDir != null) (mkBefore "");
          };
        });
    })
    # |----------------------------------------------------------------------| #
    # TODO TODO TODO TODO
    (mkIf cfg.home.enable {
      users.users = genAttrs (attrNames cfg.home.settings) (_user:
        let userCfg = cfg.home.settings."${_user}";
        in {
          name = _ _user;
          isNormalUser = _ (_user != "root");
          isSystemUser = _ (_user == "root");
          extraGroups = [ "video" "audio" "camera" ]
            ++ (optional userCfg.isSudoer "wheel");
          home = _ userCfg.homeDir;

          passwordFile = (mkIf ((isAgenixEnabled config) && cfg.agenix.enable)
            (_
              config.age.secrets."common/passwords/users/${_user}_default".path));
        });
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.home.enable && ((isAgenixEnabled config) && cfg.agenix.enable)) {
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
            let
              userCfg = cfg.home.settings."${_user}";
              toRelative = (flip absolutePathToRelativeHome) {
                inherit _user;
                cfg = config;
              };
            in {
              home = userCfg.homeDir;
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
                (toRelative userCfg.downloadsDir))
                ++ (optional (userCfg.orgDir != null)
                  (toRelative userCfg.orgDir))
                ++ (optional (userCfg.projectsDir != null)
                  (toRelative userCfg.projectsDir))
                ++ (optional (userCfg.miscDataDir != null)
                  (toRelative userCfg.miscDataDir));
            });
      }))
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
