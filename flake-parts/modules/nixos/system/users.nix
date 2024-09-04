# --- flake-parts/modules/nixos/system/users.nix
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
  secretsPath,
  pubkeys,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    genAttrs
    attrNames
    optional
    filter
    mkEnableOption
    mkOption
    types
    splitString
    ;
  inherit (lib.attrsets) attrByPath;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options)
    mkImpermanenceEnableOption
    mkAgenixEnableOption
    mkUsersSettingsOption
    ;
  inherit (localFlake.lib.attrsets) mapToAttrsAndMerge;

  cfg = config.tensorfiles.system.users;
  _ = mkOverrideAtModuleLevel;

  agenixCheck = (isModuleLoadedAndEnabled config "tensorfiles.security.agenix") && cfg.agenix.enable;
in
{
  # TODO move bluetooth dir to hardware
  options.tensorfiles.system.users = {
    enable = mkEnableOption ''
      Enables NixOS module that sets up the basis for the userspace, that is
      declarative management, basis for the home directories and also
      configures home-manager, persistence, agenix if they are enabled.
    '';

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };

    agenix = {
      enable = mkAgenixEnableOption;
    };

    usersSettings =
      mkUsersSettingsOption (_user: {
        isSudoer = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Add user to sudoers (ie the `wheel` group)
          '';
        };

        isNixTrusted = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether the user has the ability to connect to the nix daemon
            and gain additional privileges for working with nix (like adding
            binary cache)
          '';
        };

        extraGroups = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Any additional groups which the user should be a part of. This is
            basically just a passthrough for `users.users.<user>.extraGroups`
            for convenience.
          '';
        };

        agenixPassword = {
          enable = mkEnableOption ''
            TODO
          '';

          passwordSecretsPath = mkOption {
            type = types.str;
            default = "hosts/${hostName}/users/${_user}/system-password";
            description = ''
              TODO
            '';
          };
        };

        authorizedKeys = {
          enable =
            mkEnableOption ''
              TODO
            ''
            // {
              default = true;
            };

          keysRaw = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              TODO
            '';
          };

          keysSecretsAttrsetKey = mkOption {
            type = types.str;
            default = "hosts.${hostName}.users.${_user}.authorizedKeys";
            description = ''
              TODO
            '';
          };
        };
      })
      // {
        default = {
          "root" = { };
        };
      };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    { users.mutableUsers = _ false; }
    # |----------------------------------------------------------------------| #
    {
      users.users = genAttrs (attrNames cfg.usersSettings) (
        _user:
        let
          userCfg = cfg.usersSettings."${_user}";
        in
        {
          name = _ _user;
          isNormalUser = _ (_user != "root");
          isSystemUser = _ (_user == "root");
          createHome = _ true;
          extraGroups = (optional (_user != "root" && userCfg.isSudoer) "wheel") ++ userCfg.extraGroups;
          home = _ (if _user == "root" then "/root" else "/home/${_user}");

          hashedPasswordFile = mkIf (agenixCheck && userCfg.agenixPassword.enable) (
            _ config.age.secrets.${userCfg.agenixPassword.passwordSecretsPath}.path
          );

          openssh.authorizedKeys.keys =
            with userCfg.authorizedKeys;
            (mkIf enable (keysRaw ++ (attrByPath (splitString "." keysSecretsAttrsetKey) [ ] pubkeys)));
        }
      );
    }
    # |----------------------------------------------------------------------| #
    (mkIf agenixCheck {
      age.secrets = mapToAttrsAndMerge (attrNames cfg.usersSettings) (
        _user:
        let
          userCfg = cfg.usersSettings."${_user}";
        in
        with userCfg.agenixPassword;
        {
          "${passwordSecretsPath}" = mkIf enable {
            file = _ (secretsPath + "/${passwordSecretsPath}.age");
            owner = _ _user;
            # mode = _ "600";
          };
        }
      );
    })
    # |----------------------------------------------------------------------| #
    {
      nix.settings =
        let
          users = filter (_user: cfg.usersSettings."${_user}".isNixTrusted) (attrNames cfg.usersSettings);
        in
        {
          trusted-users = users;
          allowed-users = users;
        };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
