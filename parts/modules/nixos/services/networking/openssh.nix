# --- modules/services/networking/openssh.nix
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
  hostName,
  projectPath,
  secretsPath ? (projectPath + "/secrets"),
  secretsAttrset ? (
    if builtins.pathExists (secretsPath + "/secrets.nix")
    then (import (secretsPath + "/secrets.nix"))
    else {}
  ),
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;
  inherit (tensorfiles.nixos) isAgenixEnabled;
  inherit (tensorfiles.attrsets) mapToAttrsAndMerge;

  cfg = config.tensorfiles.services.networking.openssh;
  _ = mkOverrideAtModuleLevel;

  agenixCheck = (isAgenixEnabled config) && cfg.agenix.enable;
in {
  options.tensorfiles.services.networking.openssh = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles everything related to ssh,
      that is remote access, messagess, ssh-agents and ssh-keys with the
      openssh backend.
    '');

    genHostKey = {
      enable = mkAlreadyEnabledOption (mdDoc ''
        Enables autogenerating per-host based keys. Apart from certain additional
        checks this works mostly as a passthrough to
        `openssh.authorizedKeys.keys`, for more info refer to the documentation
        of said option.
      '');

      hostKey = mkOption {
        type = attrs;
        default = {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        };
        description = mdDoc ''
          TODO
        '';
      };
    };

    agenix = {
      enable = mkAgenixEnableOption;

      hostKey = {
        enable = mkEnableOption (mdDoc ''
          TODO
        '');

        privateKeySecretsPath = mkOption {
          type = str;
          default = "hosts/${hostName}/files/host_key";
          description = mdDoc ''
            TODO
          '';
        };

        privateKeyEnvPath = mkOption {
          type = str;
          default = "ssh/ssh_host_ed25519_key";
          description = mdDoc ''
            TODO
          '';
        };

        publicKeyRaw = mkOption {
          type = nullOr str;
          default = null;
          description = mdDoc ''
            TODO
          '';
        };

        publicKeySecretsAttrsetKey = mkOption {
          type = str;
          default = "publicKeys.hosts.${hostName}.hostKey";
          description = mdDoc ''
            TODO
          '';
        };

        publicKeyEnvPath = mkOption {
          type = str;
          default = "ssh/id_ed25519.pub";
          description = mdDoc ''
            TODO
          '';
        };
      };
    };

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        withKeychain = mkOption {
          type = bool;
          default = true;
          description = mdDoc ''
            TODO
          '';
        };

        authorizedKeys = {
          enable = mkAlreadyEnabledOption (mdDoc ''
            TODO
          '');

          keysRaw = mkOption {
            type = listOf str;
            default = [];
            description = mdDoc ''
              TODO
            '';
          };

          keysSecretsAttrsetKey = mkOption {
            type = str;
            default = "publicKeys.hosts.${hostName}.users.${_user}.authorizedKeys";
            description = mdDoc ''
              TODO
            '';
          };
        };

        userKey = {
          enable = mkEnableOption (mdDoc ''
            TODO
          '');

          privateKeySecretsPath = mkOption {
            type = str;
            default = "hosts/${hostName}/users/${_user}/private_key";
            description = mdDoc ''
              TODO
            '';
          };

          privateKeyHomePath = mkOption {
            type = str;
            default = ".ssh/id_ed25519";
            description = mdDoc ''
              TODO
            '';
          };

          publicKeyHomePath = mkOption {
            type = str;
            default = ".ssh/id_ed25519.pub";
            description = mdDoc ''
              TODO
            '';
          };

          publicKeyRaw = mkOption {
            type = nullOr str;
            default = null;
            description = mdDoc ''
              TODO
            '';
          };

          publicKeySecretsAttrsetKey = mkOption {
            type = str;
            default = "publicKeys.hosts.${hostName}.users.${_user}.userKey";
            description = mdDoc ''
              TODO
            '';
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      assertions = with tensorfiles.asserts; [
        (mkIf cfg.home.enable (assertHomeManagerLoaded config))
        (mkIf cfg.agenix.enable {
          assertion = let
            genHostKey = cfg.genHostKey.enable;
            setHostKey = cfg.agenix.hostKey.enable;
          in
            !(genHostKey && setHostKey);
          message = ''
            Cannot generate the host key and set it via agenix both at the same
            time. Please pick only one desired way of setting the host key.
          '';
        })
      ];
    }
    # |----------------------------------------------------------------------| #
    {
      programs.ssh = {
        startAgent = _ true;
        extraConfig = mkBefore ''
          # a private key that is used during authentication will be added to ssh-agent if it is running
          AddKeysToAgent yes
        '';
      };
      services.openssh = {
        enable = _ true;
        banner = mkBefore ''
          =====================================================================
          Welcome, you should note that this host is completely
          built/rebuilt/managed using the nix ecosystem and any manual changes
          will most probably be lost. If you are unsure about what you are
          doing, please refer to the tensorfiles documentation.

          Thank you and happy computing.
          =====================================================================
        '';
        settings = {
          PermitRootLogin = _ "no";
          PasswordAuthentication = _ false;
          StrictModes = _ true;
          KbdInteractiveAuthentication = _ false;
        };
      };
    }
    # |----------------------------------------------------------------------| #
    # (mkIf (agenixCheck && cfg.agenix.hostKey.enable) (with cfg.agenix.hostKey; {

    #   age.secrets."${privateKeySecretsPath}" = {
    #     file = _ (secretsPath + "/${privateKeySecretsPath}.age");
    #     mode = _ "700";
    #   };

    #   environment.etc."${privateKeyEnvPath}" = {
    #     source = _ (config.age.secrets."${privateKeySecretsPath}".path);
    #   };

    #   environment.etc."${publicKeyEnvPath}" = {
    #     text = let
    #       key = (if publicKeyRaw != null then
    #         publicKeyRaw
    #       else
    #         (attrsets.attrByPath (splitString "." publicKeySecretsAttrsetKey) ""
    #           secretsAttrset));
    #     in _ key;
    #   };
    # }))
    # |----------------------------------------------------------------------| #
    (mkIf cfg.genHostKey.enable {
      services.openssh.hostKeys = [cfg.genHostKey.hostKey];
    })
    # |----------------------------------------------------------------------| #
    (mkIf (agenixCheck && cfg.home.enable) {
      age.secrets = mapToAttrsAndMerge (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings.${_user};
      in
        with userCfg.userKey; {
          "${privateKeySecretsPath}" = mkIf enable {
            file = _ (secretsPath + "/${privateKeySecretsPath}.age");
            mode = _ "700";
            owner = _ _user;
          };
        });

      users.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
      in
        with userCfg.authorizedKeys; {
          openssh.authorizedKeys.keys = mkIf enable (keysRaw
            ++ (attrsets.attrByPath (splitString "." keysSecretsAttrsetKey) []
              secretsAttrset));
        });

      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
        hmConfig = config.home-manager.users.${_user};
      in
        with userCfg.userKey; {
          home.file = mkIf enable {
            "${privateKeyHomePath}".source =
              _
              (hmConfig.lib.file.mkOutOfStoreSymlink
                config.age.secrets."${privateKeySecretsPath}".path);

            "${publicKeyHomePath}".text = let
              key =
                if publicKeyRaw != null
                then publicKeyRaw
                else
                  (attrsets.attrByPath
                    (splitString "." publicKeySecretsAttrsetKey) ""
                    secretsAttrset);
            in
              _ key;
          };

          programs.keychain = mkIf userCfg.withKeychain {
            enable = _ true;
            enableBashIntegration = _ true;
            agents = ["ssh"];
            extraFlags = ["--nogui" "--quiet"];
            keys = ["id_ed25519"];
          };
        });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
