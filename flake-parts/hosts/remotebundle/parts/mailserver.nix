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
  infraVars,
}:
{
  config,
  ...
}:
let
  # selfVars = infraVars.hosts."${hostName}";

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  prometheusExporters = monitoringVars.services.prometheus.exporters;

  # --- prometheus exporters ---
  mailserverExporters = infraVars.hosts."remotebundle".services.prometheus.exporters;
in
{
  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [ ];

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

  # Mailserver
  tensorfiles.services.mailserver = {
    enable = true;
    roundcube.enable = true;
    rspamd-ui.enable = true;
  };
  mailserver.stateVersion = 3;
  services.rspamd.locals."worker-controller.inc".text = ''
    secure_ip = "0.0.0.0/0, ::/0";
  '';

  services.dovecot2 = {
    mailPlugins.globally.enable = [ "old_stats" ];
    extraConfig = ''
      service old-stats {
        unix_listener old-stats {
          user = ${config.services.dovecot2.user}
          group = ${config.services.dovecot2.group}
          mode = 0660
        }
        fifo_listener old-stats-mail {
          mode = 0660
          user = ${config.services.dovecot2.user}
          group = ${config.services.dovecot2.group}
        }
        fifo_listener old-stats-user {
          mode = 0660
          user = ${config.services.dovecot2.user}
          group = ${config.services.dovecot2.group}
        }
      }
      plugin {
        old_stats_refresh = 30 secs
        old_stats_track_cmds = yes
      }
    '';
  };

  services.rspamd = {
    workers.controller.bindSockets = [
      {
        socket = "/run/rspamd/worker-controller.sock";
        mode = "0666";
      }
      "0.0.0.0:${toString mailserverExporters.rspamd.targetPort}"
    ];
  };

  services.prometheus.exporters = {
    postfix = {
      enable = true;
      inherit (prometheusExporters.postfix) port;
      logfilePath = "/var/log/mail";
    };

    rspamd = {
      enable = true;
      inherit (prometheusExporters.rspamd) port;
    };

    dovecot = {
      enable = true;
      inherit (config.services.dovecot2) user group;
      inherit (prometheusExporters.dovecot) port;
      socketPath = "/var/run/dovecot2/old-stats";
      scopes = [
        "user"
        "global"
      ];
    };
  };

  age.secrets = {
    #
  };
}
