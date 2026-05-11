# --- flake-parts/hosts/remotebundle/parts/mailserver.nix
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
  inputs,
  infraVars,
  secretsPath,
}:
{
  config,
  pkgs,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
  mailserverVars = selfVars.services.mailserver;

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  prometheusExporters = monitoringVars.services.prometheus.exporters;

  # --- prometheus exporters ---
  mailserverExporters = infraVars.hosts."remotebundle".services.prometheus.exporters;

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;

  mkAccountPath = acc: config.age.secrets."hosts/${hostName}/mailserver/${acc}".path;
in
{
  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [ inputs.nixos-mailserver.nixosModules.default ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ ];

  tensorfiles = {
    services.monit = {
      enable = true;
      alertAddress = "monitoring@tsandrini.sh";
      mailserver.enable = true;
      checks = {
        filesystem.root.enable = false;
        system = {
          enable = true;
          loadavg_1min.enable = false;
          loadavg_5min.enable = false;
          loadavg_15min.enable = false;
        };
        processes = {
          sshd = {
            enable = true;
            port = infraVars.common.services.openssh.defaultPort;
          };
          postfix.enable = true;
          dovecot = {
            enable = true;
            fqdn = "mail.tsandrini.sh";
          };
          rspamd.enable = true;
        };
      };
    };
  };

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
      allowedUDPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        #
      ];
    };
  };

  services.fail2ban = {
    jails = {
      postfix.settings = {
        enabled = true;
        filter = "postfix";
        findtime = "4h";
        bantime = "2d";
      };
      dovecot.settings = {
        enabled = true;
        filter = "dovecot";
        mode = "aggressive";
        findtime = "3h";
        bantime = "2d";
      };
    };
  };

  services.rspamd.locals."worker-controller.inc".text = ''
    secure_ip = "0.0.0.0/0, ::/0";
  '';

  services.dovecot2.settings = {
    mail_plugins.old_stats = true;
    service = [
      {
        _section.name = "old-stats";
        "unix_listener old-stats" = {
          user = config.services.dovecot2.settings.default_internal_user;
          group = config.services.dovecot2.settings.default_internal_group;
          mode = "0660";
        };
        "fifo_listener old-stats-mail" = {
          mode = "0660";
          user = config.services.dovecot2.settings.default_internal_user;
          group = config.services.dovecot2.settings.default_internal_group;
        };
        "fifo_listener old-stats-user" = {
          mode = "0660";
          user = config.services.dovecot2.settings.default_internal_user;
          group = config.services.dovecot2.settings.default_internal_group;
        };
      }
    ];
    plugin = {
      old_stats_refresh = "30 secs";
      old_stats_track_cmds = true;
    };
  };

  services.rspamd = {
    workers.controller.bindSockets = [
      {
        socket = "/run/rspamd/worker-controller.sock";
        mode = "0666";
      }
      "0.0.0.0:${toString mailserverExporters.rspamd.port}"
    ];
  };

  services.nginx = {
    enable = true;

    virtualHosts."${virtualHostsVar."rspamd".domain}" = {
      enableACME = true;
      forceSSL = true;

      basicAuthFile = config.age.secrets."hosts/${hostName}/mailserver/rspamd-ui-basic-auth-file".path;
      locations."/" = {
        proxyPass = "http://${virtualHostsVar."rspamd".proxyEndpoint}";
      };
    };

    # NOTE: This is used to setup HTTP challenges to our fqdn domain for our mailserver
    virtualHosts.${config.mailserver.fqdn} = {
      enableACME = true;
    };
  };

  services.roundcube = {
    enable = true;
    dicts = with pkgs.aspellDicts; [
      en
      en-computers
      en-science
      cs
    ];
    plugins = [
      "emoticons"
      "enigma"
      "userinfo"
      "zipdownload"
      "markasjunk"
      "jqueryui"
    ];
    hostName = virtualHostsVar."roundcube".domain;
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_host'] = "ssl://${config.mailserver.fqdn}";
      $config['imap_host'] = "ssl://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    inherit (mailserverVars) fqdn domains;

    x509.useACMEHost = config.mailserver.fqdn;

    enableManageSieve = true;
    virusScanning = false;

    monitoring = {
      enable = false; # NOTE: we use our own monitoring monit module
      alertAddress = infraVars.common.contacts.monitoringEmail;
    };

    accounts = {
      "${mailserverVars.securityEmail}" = {
        hashedPasswordFile = mkAccountPath "security-at-tsandrini-dot-sh";
        aliases = [
          "admin@${mailserverVars.primaryDomain}"
          "info@${mailserverVars.primaryDomain}"
          "abuse@${mailserverVars.primaryDomain}"
          "postmaster@${mailserverVars.primaryDomain}"
        ];
      };

      "t@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "t-at-tsandrini-dot-sh";
        aliases = [
          "default@${mailserverVars.primaryDomain}"
          "tsandrini@${mailserverVars.primaryDomain}"
          "ts@${mailserverVars.primaryDomain}"
          "st@${mailserverVars.primaryDomain}"
          "sandrint@${mailserverVars.primaryDomain}"
          "sandrini@${mailserverVars.primaryDomain}"
          "sandrinit@${mailserverVars.primaryDomain}"
          "tom@${mailserverVars.primaryDomain}"
          "tomas@${mailserverVars.primaryDomain}"
          "ter@${mailserverVars.primaryDomain}"
          "personal@${mailserverVars.primaryDomain}"
        ];
      };

      "business@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "business-at-tsandrini-dot-sh";
        aliases = [
          "work@${mailserverVars.primaryDomain}"
          "jobs@${mailserverVars.primaryDomain}"
          "offers@${mailserverVars.primaryDomain}"
          "prace@${mailserverVars.primaryDomain}"
        ];
      };

      "monitoring@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "monitoring-at-tsandrini-dot-sh";
        aliases = [
          "alerts@${mailserverVars.primaryDomain}"
          "notifications@${mailserverVars.primaryDomain}"
        ];
      };

      "shopping@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "shopping-at-tsandrini-dot-sh";
        aliases = [
          "shops@${mailserverVars.primaryDomain}"
          "shop@${mailserverVars.primaryDomain}"
          "obchody@${mailserverVars.primaryDomain}"
        ];
      };

      "newsletters@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "newsletters-at-tsandrini-dot-sh";
        aliases = [ ];
      };

      "grafana-bot@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "grafana-bot-at-tsandrini-dot-sh";
        aliases = [ ];
      };

      "immich-bot@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "immich-bot-at-tsandrini-dot-sh";
        aliases = [ ];
      };

      "git-bot@${mailserverVars.primaryDomain}" = {
        hashedPasswordFile = mkAccountPath "git-bot-at-tsandrini-dot-sh";
        aliases = [ ];
      };
    };
  };

  services.prometheus.exporters = {
    postfix = {
      enable = true;
      inherit (prometheusExporters.postfix) port;
      logfilePath = "/var/log/mail";
    };

    dovecot = {
      enable = true;
      user = config.services.dovecot2.settings.default_internal_user;
      group = config.services.dovecot2.settings.default_internal_group;
      inherit (prometheusExporters.dovecot) port;
      socketPath = "/var/run/dovecot2/old-stats";
      scopes = [
        "user"
        "global"
      ];
    };
  };

  age.secrets = {
    "hosts/${hostName}/mailserver/rspamd-ui-basic-auth-file" = {
      file = secretsPath + "/hosts/${hostName}/mailserver/rspamd-ui-basic-auth-file.age";
      owner = config.services.nginx.user;
    };

    # --- accounts --
    "hosts/${hostName}/mailserver/security-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/security-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/t-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/t-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/business-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/business-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/monitoring-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/monitoring-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/shopping-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/shopping-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/newsletters-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/newsletters-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/grafana-bot-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/grafana-bot-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/immich-bot-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/immich-bot-at-tsandrini-dot-sh.age";

    "hosts/${hostName}/mailserver/git-bot-at-tsandrini-dot-sh".file =
      secretsPath + "/hosts/${hostName}/mailserver/git-bot-at-tsandrini-dot-sh.age";
  };
}
