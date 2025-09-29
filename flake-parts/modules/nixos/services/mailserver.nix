# --- flake-parts/modules/nixos/services/mailserver.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
  inputs,
  secretsPath,
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
    types
    mkMerge
    mkEnableOption
    mkOption
    attrNames
    ;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkAgenixEnableOption mkSubmodulesOption;
  inherit (localFlake.lib.strings) sanitizeEmailForNixStorePath;
  inherit (localFlake.lib.attrsets) mapToAttrsAndMerge;

  cfg = config.tensorfiles.services.mailserver;
  _ = mkOverrideAtProfileLevel;

  agenixCheck = (isModuleLoadedAndEnabled config "tensorfiles.security.agenix") && cfg.agenix.enable;

  defaultDomain = "tsandrini.sh";
in
{
  options.tensorfiles.services.mailserver = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the mailserver system profile.
    '';

    agenix = {
      enable = mkAgenixEnableOption;
    };

    baseDomain = mkOption {
      type = types.str;
      default = defaultDomain;
      description = ''
        The base domain of the mailserver.
      '';
    };

    additionalDomains = mkOption {
      type = types.listOf types.str;
      default = [
        "tsandrini.cz"
        "tsandrini.tech"
      ];
      description = ''
        Additional domains that the mailserver should handle.
      '';
    };

    accounts =
      mkSubmodulesOption (_account: {
        enable =
          mkEnableOption ''
            Enables the account.
          ''
          // {
            default = true;
          };

        agenixHashedPasswordFile = {
          enable =
            mkEnableOption ''
              Enables the use of age encrypted hashed password file for the account.
            ''
            // {
              default = true;
            };

          hashedPasswordFileSecretsPath = mkOption {
            type = types.str;
            default = "hosts/${hostName}/mailserver/${sanitizeEmailForNixStorePath _account}";
            description = ''
              The path where the age encrypted hashed password file secrets are stored.
            '';
          };
        };

        aliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            A list of aliases for the account.
          '';
        };
      })
      // {
        default = {
          "t@${defaultDomain}" = {
            aliases = [
              "default@${defaultDomain}"
              "tsandrini@${defaultDomain}"
              "ts@${defaultDomain}"
              "st@${defaultDomain}"
              "sandrint@${defaultDomain}"
              "sandrini@${defaultDomain}"
              "sandrinit@${defaultDomain}"
              "tom@${defaultDomain}"
              "tomas@${defaultDomain}"
              "ter@${defaultDomain}"
              "personal@${defaultDomain}"
            ];
          };
          "business@${defaultDomain}" = {
            aliases = [
              "work@${defaultDomain}"
              "jobs@${defaultDomain}"
              "offers@${defaultDomain}"
              "prace@${defaultDomain}"
            ];
          };
          "security@${defaultDomain}" = {
            aliases = [
              "admin@${defaultDomain}"
              "info@${defaultDomain}"
            ];
          };
          "monitoring@${defaultDomain}" = {
            aliases = [
              "alerts@${defaultDomain}"
              "notifications@${defaultDomain}"
            ];
          };
          "shopping@${defaultDomain}" = {
            aliases = [ ];
          };
          "newsletters@${defaultDomain}" = {
            aliases = [ ];
          };
          "grafana-bot@${defaultDomain}" = {
            aliases = [ ];
          };
          "git-bot@${defaultDomain}" = {
            aliases = [ ];
          };
        };
      };

    roundcube = {
      enable = mkEnableOption ''
        Enables integration with the Roundcube webmail client.
      '';
    };

    rspamd-ui = {
      enable = mkEnableOption ''
        Enables the Rspamd web UI.
      '';

      agenixBasicAuthFile = {
        enable =
          mkEnableOption ''
            Enables the use of age encrypted basic auth file for the Rspamd UI.
          ''
          // {
            default = true;
          };

        basicAuthFileSecretsPath = mkOption {
          type = types.str;
          default = "hosts/${hostName}/mailserver/rspamd-ui-basic-auth-file";
          description = ''
            The path where the age encrypted basic auth file secrets are stored.
          '';
        };
      };
    };

    fail2ban-jails = {
      enable =
        mkEnableOption ''
          Enables the fail2ban jails for the mailserver.
          Namely the postfix and dovecot jails.
        ''
        // {
          default = true;
        };
    };
  };

  # --------------------------
  imports = with inputs; [ nixos-mailserver.nixosModules.default ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      mailserver = {
        enable = _ true;
        stateVersion = _ 1;
        fqdn = _ "mail.${cfg.baseDomain}";
        domains = [ cfg.baseDomain ] ++ cfg.additionalDomains;

        loginAccounts = mapToAttrsAndMerge (attrNames cfg.accounts) (
          _account:
          let
            accountCfg = cfg.accounts.${_account};
          in
          {
            "${_account}" = mkIf accountCfg.enable {
              inherit (accountCfg) aliases;
              hashedPasswordFile = mkIf (agenixCheck && accountCfg.agenixHashedPasswordFile.enable) (
                _ config.age.secrets."${accountCfg.agenixHashedPasswordFile.hashedPasswordFileSecretsPath}".path
              );
            };
          }
        );

        # Use Let's Encrypt certificates. Note that this needs to set up a stripped
        # down nginx and opens port 80.
        certificateScheme = _ "acme-nginx";
        enableManageSieve = _ true;
        virusScanning = _ false;

        monitoring = {
          enable = _ false;
          alertAddress = _ "monitoring@${cfg.baseDomain}";
        };
      };
      security.acme.acceptTerms = _ true;
      security.acme.defaults.email = _ "security@${cfg.baseDomain}";
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.roundcube.enable {
      services.roundcube = {
        enable = _ true;
        # this is the url of the vhost, not necessarily the same as the fqdn of
        # the mailserver
        hostName = _ "webmail.${cfg.baseDomain}";
        extraConfig = ''
          # starttls needed for authentication, so the fqdn required to match
          # the certificate
          $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
          $config['smtp_user'] = "%u";
          $config['smtp_pass'] = "%p";
        '';
      };
      services.nginx.enable = _ true;
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.fail2ban-jails.enable {
      services.fail2ban = {
        jails = {
          postfix.settings = {
            enabled = _ true;
            filter = _ "postfix";
            findtime = _ "4h";
            bantime = _ "2d";
          };
          dovecot.settings = {
            enabled = _ true;
            filter = _ "dovecot";
            mode = _ "aggressive";
            findtime = _ "3h";
            bantime = _ "2d";
          };
        };
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.rspamd-ui.enable {
      services.nginx.virtualHosts.rspamd = {
        forceSSL = _ true;
        enableACME = _ true;
        basicAuthFile = mkIf (agenixCheck && cfg.rspamd-ui.agenixBasicAuthFile.enable) (
          _ config.age.secrets."${cfg.rspamd-ui.agenixBasicAuthFile.basicAuthFileSecretsPath}".path
        );
        serverName = _ "rspamd.${cfg.baseDomain}";
        locations = {
          "/" = {
            proxyPass = _ "http://unix:/run/rspamd/worker-controller.sock:/";
          };
        };
      };
      services.nginx.enable = _ true;
    })
    # |----------------------------------------------------------------------| #
    (mkIf (agenixCheck && cfg.rspamd-ui.enable && cfg.rspamd-ui.agenixBasicAuthFile.enable) {
      age.secrets."${cfg.rspamd-ui.agenixBasicAuthFile.basicAuthFileSecretsPath}" = {
        file = _ (secretsPath + "/${cfg.rspamd-ui.agenixBasicAuthFile.basicAuthFileSecretsPath}.age");
        owner = _ config.services.nginx.user;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf agenixCheck {
      age.secrets = mapToAttrsAndMerge (attrNames cfg.accounts) (
        _account:
        let
          accountCfg = cfg.accounts.${_account};
        in
        {
          "${accountCfg.agenixHashedPasswordFile.hashedPasswordFileSecretsPath}" =
            mkIf (accountCfg.enable && accountCfg.agenixHashedPasswordFile.enable)
              {
                file = _ (
                  secretsPath + "/${accountCfg.agenixHashedPasswordFile.hashedPasswordFileSecretsPath}.age"
                );
                # mode = _ "600";
              };
        }
      );
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
