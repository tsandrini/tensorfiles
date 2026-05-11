# --- flake-parts/hosts/remotebundle/parts/monitoring.nix
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
  secretsPath,
  infraVars,
}:
{
  config,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  grafanaVars = monitoringVars.services.grafana;
  lokiVars = monitoringVars.services.loki;
  prometheusVars = monitoringVars.services.prometheus;

  # --- database ---
  postgresVars = selfVars.services.postgresql;
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
    services.monitoring.loki.enable = true;
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
        config.services.loki.configuration.server.http_listen_port
      ];
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics.reporting_enabled = false;
      server = {
        inherit (grafanaVars.server) http_addr http_port;
        inherit (virtualHostsVar."grafana") domain;

        root_url = "https://${virtualHostsVar."grafana".domain}";
        enforce_domain = true;
        enable_gzip = true;
      };

      smtp = {
        enabled = true;
        host = "mail.tsandrini.sh:465";
        user = "grafana-bot@tsandrini.sh";
        password = "$__file{${config.age.secrets."hosts/${hostName}/grafana-bot-mail-password".path}}";
        fromAddress = "grafana-bot@tsandrini.sh";
      };

      database = {
        type = "postgres";
        host = "/run/postgresql";
        inherit (postgresVars.instances."grafana") user;
        name = postgresVars.instances."grafana".database;
      };
      # NOTE enable again on init
      security = {
        disable_initial_admin_creation = true;

        admin_email = "t@tsandrini.sh";
        admin_password = "$__file{${config.age.secrets."hosts/${hostName}/grafana-admin-password".path}}";
        secret_key = "$__file{${config.age.secrets."hosts/${hostName}/grafana-secret-key".path}}";
      };
    };
    provision = {
      datasources.settings.datasources = [
        {
          uid = "vOqQHM-f7fecKnIgFdV4OnVuvHU6Pfbd";
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString prometheusVars.server.http_port}";
        }
        {
          uid = "x2dSQip31bGxOYQBo3GtZdCtCz9Tbt1q";
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString lokiVars.server.http_port}";
        }
      ];
      dashboards.settings.providers =
        map
          (
            attrs:
            {
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = true;
              allowUiUpdates = true;
            }
            // attrs
          )
          [
            {
              name = "Node Exporter Full";
              options.path = ../grafana/dashboards/node-exporter-full.json;
            }
            {
              name = "NGINX by nginxinc";
              options.path = ../grafana/dashboards/nginx-by-nginxinc.json;
            }
            {
              name = "PostgreSQL Database";
              options.path = ../grafana/dashboards/postgresql-database.json;
            }
            # --- DNS ---
            {
              name = "Pi-hole Exporter";
              options.path = ../grafana/dashboards/pi-hole-exporter.json;
              folder = "DNS";
            }
            {
              name = "Pi-hole UI";
              options.path = ../grafana/dashboards/pi-hole-ui.json;
              folder = "DNS";
            }
            {
              name = "Unbound";
              options.path = ../grafana/dashboards/unbound.json;
              folder = "DNS";
            }
            # --- Logs ---
            {
              name = "Logs / App";
              options.path = ../grafana/dashboards/logs-app.json;
              folder = "Logs & Loki";
            }
            {
              name = "Loki & Promtail";
              options.path = ../grafana/dashboards/loki-and-promtail.json;
              folder = "Logs & Loki";
            }
            {
              name = "Loki Metrics Dashboard";
              options.path = ../grafana/dashboards/loki-metrics-dashboard.json;
              folder = "Logs & Loki";
            }
            # --- Mailserver ---
            {
              name = "dovecot2 (old_stats) overview by tsandrini";
              options.path = ../grafana/dashboards/dovecot2-old-stats-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
            {
              name = "Postfix";
              options.path = ../grafana/dashboards/postfix.json;
              folder = "Mailserver";
            }
            {
              name = "Postfix overview by tsandrini";
              options.path = ../grafana/dashboards/postfix-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
            {
              name = "Rspamd stat overview by tsandrini";
              options.path = ../grafana/dashboards/rspamd-stat-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
          ];
    };
  };

  services.prometheus = {
    enable = true;
    port = prometheusVars.server.http_port;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs =
      let
        mkTarget =
          host: service:
          "${infraVars.hosts.${host}.address}:${
            toString infraVars.hosts.${host}.services.prometheus.exporters.${service}.port
          }";
        mkAnubisTarget =
          host: virtualHost:
          "${infraVars.hosts.${host}.address}:${
            toString infraVars.hosts.${host}.services.nginx.virtualHosts.${virtualHost}.anubisMetricsPort
          }";
      in
      [
        {
          job_name = "NixOS-node-exporter";
          static_configs = [
            {
              # targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
              targets = [
                (mkTarget "remotebundle" "node")
                (mkTarget "pupibundle" "node")
              ];
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.port}" ];
            }
          ];
        }
        {
          job_name = "postgres";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "postgres")
              ];
            }
          ];
        }
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "nginx")
              ];
            }
          ];
        }
        {
          job_name = "postfix";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "postfix")
              ];
            }
          ];
        }
        {
          job_name = "rspamd";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "rspamd")
              ];
            }
          ];
        }
        {
          job_name = "dovecot";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "dovecot")
              ];
            }
          ];
        }
        {
          job_name = "pihole";
          static_configs = [
            {
              targets = [
                (mkTarget "pupibundle" "pihole")
              ];
            }
          ];
        }
        {
          job_name = "unbound";
          static_configs = [
            {
              targets = [
                (mkTarget "pupibundle" "unbound")
              ];
            }
          ];
        }
        {
          job_name = "nginxlog";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "nginxlog")
              ];
            }
          ];
        }
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [
                (mkTarget "remotebundle" "loki")
              ];
            }
          ];
        }
        {
          job_name = "anubis";
          static_configs = [
            {
              targets = [
                (mkAnubisTarget "remotebundle" "immutable-insights")
                (mkAnubisTarget "remotebundle" "pgadmin")
                (mkAnubisTarget "remotebundle" "grafana")
                (mkAnubisTarget "remotebundle" "forgejo")
              ];
            }
          ];
        }
      ];
  };

  services.loki.configuration.server = {
    http_listen_address = lokiVars.server.http_addr;
    http_listen_port = lokiVars.server.http_port;
  };

  services.prometheus.exporters = {
    #
  };

  age.secrets = {
    "hosts/${hostName}/grafana-bot-mail-password" = {
      file = "${secretsPath}/hosts/${hostName}/grafana-bot-mail-password.age";
      owner = "grafana";
    };

    "hosts/${hostName}/grafana-admin-password" = {
      file = "${secretsPath}/hosts/${hostName}/grafana-admin-password.age";
      owner = "grafana";
    };

    "hosts/${hostName}/grafana-secret-key" = {
      file = "${secretsPath}/hosts/${hostName}/grafana-secret-key.age";
      owner = "grafana";
    };
  };
}
