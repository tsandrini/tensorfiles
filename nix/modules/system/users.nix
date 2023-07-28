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
  cfg = config.tensorfiles.system.users;
  _ = mkOverride 500;
  mergeAttrs = attrs: foldl' (acc: elem: acc // elem) { } attrs;
  persistenceCheck = (cfg.persistence)
    && (config ? tensorfiles.system.persistence)
    && (config.tensorfiles.system.persistence.enable);
  agenixCheck = (cfg.agenix) && (config ? tensorfiles.security.agenix)
    && (config.tensorfiles.security.agenix);
in {
  # TODO move bluetooth dir to hardware
  options.tensorfiles.system.users = with types; {
    enable = mkEnableOption (mdDoc ''
      Module predefining certain nix lang & nix package manager
      defaults
    '');

    persistence = mkEnableOption (mdDoc ''
      Whether to autoappend files/folders to the persistence system.
      Note that this will get executed only if

      1. persistence = true;
      2. tensorfiles.system.persistence module is loaded
      3. tensorfiles.system.persistence.enable = true;
    '') // {
      default = true;
    };

    agenix = mkEnableOption (mdDoc ''
      Whether to enable setting password as passwordFiles from agenix.
      The folder structure for individual users should follow the convention:

      - `secrets/common/passwords/users/$user_default.age`

      if this is not okay for you, you should set the password manually yourself
      instead.

      Note that this will get executed only if

      1. agenix = true;
      2. tensorfiles.security.agenix module is loaded
      3. tensorfiles.security.agenix.enable = true;
    '') // {
      default = true;
    };

    home = {
      enable = mkEnableOption (mdDoc ''
        Enable multi-user configuration via home-manager.

        The configuration is then done via the settings option with the toplevel
        attribute being the name of the user, for example:

        ```nix
        home.enable = true;
        home.settings."root" = {
          myOption = false;
          otherOption.name = "test1";
          # etc...
        };
        home.settings."myUser" = {
          myOption = true;
          otherOption.name = "test2";
          # etc...
        };
        ```
      '');

      settings = mkOption {
        type = attrsOf (submodule ({ name, ... }: {
          options = {

            #
          };
        }));
        # Note: It's sufficient to just create the toplevel attribute and the
        # rest will be automatically populated with the default option values.
        default = { "${user}" = { }; };
        description = mdDoc ''
          The configuration is then done via the settings option with the toplevel
          attribute being the name of the user, for example:

          ```nix
          home.enable = true;
          home.settings."root" = {
            myOption = false;
            otherOption.name = "test1";
            # etc...
          };
          home.settings."myUser" = {
            myOption = true;
            otherOption.name = "test2";
            # etc...
          };
          ```
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      assertions = [
        {
          assertion = hasAttr "persistence" config.environment;
          message =
            "environment.persistence missing, please install and import the impermanence module";
        }
        (mkIf cfg.home.enable {
          assertion = cfg.home.enable && (hasAttr "home-manager" config);
          message =
            "home configuration enabled, however, home-manager missing, please install and import the home-manager module";
        })
      ];
    })
    ({ users.mutableUsers = _ false; })
    (mkIf cfg.home.enable {
      home-manager.useGlobalPkgs = _ true;
      home-manager.useUserPackages = _ true;
    })
    (mkIf cfg.home.enable (let
      mkModuleForUser = _user:
        let userCfg = cfg.home.settings.${_user};
        in {
          home-manager.users.${_user} = {
            home = {
              username = _ "${_user}";
              homeDirectory = _ "/home/${_user}";
              stateVersion = _ "23.05";
            };
            fonts.fontconfig.enable = _ true;
          };

          users.users.${_user} = {
            isNormalUser = _ true;
            extraGroups =
              [ "wheel" "video" "audio" "camera" "networkmanager" "lightdm" ];
            home = _ "/home/${_user}";
          };

          environment.persistence = mkIf persistenceCheck {
            "/persist".users.${user} = {
              directories = [
                "Downloads"
                "FiberBundle"
                "org"
                "ProjectBundle"
                "ZoteroStorage"
                {
                  directory = ".gnupg";
                  mode = "0700";
                }
                {
                  directory = ".ssh";
                  mode = "0700";
                }
              ];
            };
          };

          age.secrets = mkIf agenixCheck {
            "common/passwords/users/${_user}_default".file =
              _ ../../secrets/common/passwords/users/${_user}_default.age;
          };
        };
    in mergeAttrs (map mkModuleForUser (attrNames cfg.home.settings))))
    # -------------------------
    # (mkIf (persistenceCheck && !cfg.home.enable) {
    #   #
    # })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
