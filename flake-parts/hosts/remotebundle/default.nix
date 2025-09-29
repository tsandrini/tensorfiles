# --- flake-parts/hosts/remotebundle/default.nix
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
{ inputs, secretsPath }:
{
  pkgs,
  config,
  lib,
  system,
  hostName,
  ...
}:
let
  domain = "tsandrini.sh";
  grafanaDomain = "grafana.${domain}";
  pgadminDomain = "pgadmin.${domain}";
  # fireflyDomain = "firefly.${domain}";
  forgejoDomain = "git.${domain}";
  immutable-insights = inputs.immutable-insights.packages.${system}.default;
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # VPSfree container

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    (inputs.vpsadminos + "/os/lib/nixos-container/vpsadminos.nix")
    (inputs.nix-mineral + "/nix-mineral.nix")

    ./nm-overrides.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [ ];

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------

  tensorfiles = {
    profiles = {
      headless.enable = true;
      packages-base.enable = true;
      # packages-extra.enable = true;
      with-base-monitoring-exports.enable = true;
      with-base-monitoring-exports.prometheus.exporters.node.openFirewall = false;
    };

    services.mailserver.enable = true;
    services.mailserver.roundcube.enable = true;
    services.mailserver.rspamd-ui.enable = true;

    services.monit = {
      enable = true;
      alertAddress = "monitoring@${domain}";
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
            port = 2222;
          };
          postfix.enable = true;
          dovecot = {
            enable = true;
            fqdn = "mail.${domain}";
          };
          rspamd.enable = true;
        };
      };
    };

    services.monitoring.loki.enable = true;

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;

    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
      extraGroups = [ "input" ];
    };
  };

  nix-mineral.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      51821
    ];
  };

  networking.wireguard.interfaces = {
    wg-home-tunnel = {
      ips = [ "10.0.33.13/32" ];
      listenPort = 51821;
      privateKeyFile = config.age.secrets."hosts/${hostName}/wg-home-tunnel-privkey".path;

      peers = [
        {
          publicKey = "RY2XHIRk+2RtA27EUQdLj+CcqAP2Izj4cGI3Nm0d5CE="; # pragma: allowlist secret

          allowedIPs = [
            "10.10.0.0/24"
            "10.20.0.0/24"
            "10.0.33.1/32"
            "10.0.0.0/24"
            "10.5.0.0/24"
          ];

          endpoint = "[2a02:8308:298:c900::a]:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  systemd.extraConfig = ''
    DefaultTimeoutStartSec=900s
  '';

  users.users.nginx.extraGroups = [
    config.users.groups.anubis.name
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    commonHttpConfig = ''
      # Define rate limiting zones
      limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;
      limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

      # Set log level to notice to catch rate limiting events
      error_log /var/log/nginx/error.log notice;
      limit_req_log_level notice;
      limit_conn_log_level notice;

      proxy_headers_hash_max_size 1024;
      proxy_headers_hash_bucket_size 128;
    '';

    statusPage = true;
    virtualHosts.localhost = {
      serverAliases = [ "127.0.0.1" ];
      listenAddresses = [ "127.0.0.1" ];
      locations."/nginx_status" = {
        extraConfig = ''
          stub_status on;
          access_log off;
          allow 127.0.0.1;
          deny all;
        '';
      };
    };

    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.immutable-insights.settings.BIND}";
      };
      # locations."/metrics" = {
      #   proxyPass = "http://unix:${config.services.anubis.instances."".settings.METRICS_BIND}";
      # };
    };

    virtualHosts."upstream-${domain}" = {
      serverName = domain;
      listen = [ { addr = "unix:/run/nginx/nginx.sock"; } ];

      root = "${immutable-insights}/var/www";

      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.html";
        };
        "~* \\.(js|css|png|jpg|jpeg|gif|svg|ico)$" = {
          extraConfig = ''
            expires 30d;
            add_header Cache-Control "public, no-transform";
          '';
        };
      };
    };

    virtualHosts."${grafanaDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.grafana.settings.BIND}";
      };
    };

    virtualHosts."${pgadminDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        # proxyPass = "http://localhost:${toString config.services.pgadmin.port}";
        proxyPass = "http://unix:${config.services.anubis.instances.pgadmin.settings.BIND}";
      };
    };

    virtualHosts."${forgejoDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.forgejo.settings.BIND}";
      };
    };
  };

  services.forgejo = {
    enable = true;
    database = {
      createDatabase = false;
      type = "postgres";
      socket = "/run/postgresql";
    };
    settings = {
      server = {
        ROOT_URL = "https://${forgejoDomain}/";
        DOMAIN = forgejoDomain;
        SSH_PORT = 2222;
        LANDING_PAGE = "explore";
      };
      service = {
        DISABLE_REGISTRATION = true;
        COOKIE_SECURE = true;
        ENABLE_NOTIFY_MAIL = true;
        REGISTER_EMAIL_CONFIRM = true;
      };
      indexer = {
        REPO_INDEXER_ENABLED = true;
      };
      mailer = {
        ENABLED = true;
        PROTOCOL = "smtp"; # <--- Change protocol
        SMTP_ADDR = "localhost";
        FROM = "git-bot@${domain}";
      };
      DEFAULT = {
        APP_NAME = "tsandrini's git";
      };
    };
  };

  systemd.services.forgejo = {
    path = [ pkgs.system-sendmail ];
  };

  # Add firefly-pico and firefly-importer
  # services.firefly-iii = {
  #   enable = true;
  #   virtualHost = fireflyDomain;
  #   enableNginx = true;
  #   settings = {
  #     APP_KEY_FILE = config.age.secrets."hosts/${hostName}/firefly-iii-app-key".path;
  #     APP_URL = "https://${config.services.firefly-iii.virtualHost}";
  #     DB_CONNECTION = "pgsql";
  #     DB_HOST = "/run/postgresql";
  #     SITE_OWNER = "t@${domain}";
  #     TZ = "Europe/Prague";
  #   };
  # };
  #
  # services.firefly-pico = {
  #   enable = true;
  #   enableNginx = true;
  #   virtualHost = "firefly-pico.${domain}";
  #   settings = {
  #     APP_URL = "https://${config.services.firefly-pico.virtualHost}";
  #     TZ = "Europe/Berlin";
  #     FIREFLY_URL = config.services.firefly-iii.settings.APP_URL;
  #     SITE_OWNER = "t@${domain}";
  #     # APP_KEY_FILE = config.age.secrets.firefly-pico-app-key.path;
  #   };
  # };

  services.anubis = {
    defaultOptions = {
      settings = {
        SERVE_ROBOTS_TXT = true;
        OG_PASSTHROUGH = true;
      };
    };

    instances = {
      immutable-insights = {
        enable = true;
        group = "nginx";
        settings = {
          TARGET = "unix:///run/nginx/nginx.sock";
        };
      };

      forgejo = {
        enable = true;
        settings = {
          TARGET = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
        };
      };

      grafana = {
        enable = true;
        settings = {
          TARGET = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        };
      };

      pgadmin = {
        enable = true;
        settings = {
          TARGET = "http://localhost:${toString config.services.pgadmin.port}";
        };
      };

      # firefly = {
      #   enable = true;
      #   group = "nginx";
      #   settings = {
      #     TARGET = "unix:///run/nginx/firefly.sock";
      #   };
      # };
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics.reporting_enabled = false;
      server = {
        root_url = "https://${grafanaDomain}";
        domain = "${grafanaDomain}";
        enforce_domain = true;
        enable_gzip = true;
        http_addr = "127.0.0.1";
        http_port = 3001;
      };

      smtp = {
        enabled = true;
        host = "mail.${domain}:587";
        user = "grafana-bot@${domain}";
        password = "$__file{${config.age.secrets."hosts/${hostName}/grafana-bot-mail-password".path}}";
        fromAddress = "grafana-bot@${domain}";
      };

      database = {
        type = "postgres";
        name = "grafana";
        host = "/run/postgresql";
        user = "grafana";
      };
      # NOTE enable again on init
      security.disable_initial_admin_creation = true;

      security.admin_email = "t@${domain}";
      security.admin_password = "$__file{${
        config.age.secrets."hosts/${hostName}/grafana-admin-password".path
      }}";
    };
    provision = {
      datasources.settings.datasources = [
        {
          uid = "vOqQHM-f7fecKnIgFdV4OnVuvHU6Pfbd";
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        {
          uid = "x2dSQip31bGxOYQBo3GtZdCtCz9Tbt1q";
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
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
              options.path = ./grafana/dashboards/node-exporter-full.json;
            }
            {
              name = "Logs / App";
              options.path = ./grafana/dashboards/logs-app.json;
            }
            {
              name = "Prometheus 2.0 Overview";
              options.path = ./grafana/dashboards/prometheus-2-0-overview.json;
            }
            {
              name = "NGINX by nginxinc";
              options.path = ./grafana/dashboards/nginx-by-nginxinc.json;
            }
            {
              name = "PostgreSQL Database";
              options.path = ./grafana/dashboards/postgresql-database.json;
            }
            {
              name = "Loki & Promtail";
              options.path = ./grafana/dashboards/loki-and-promtail.json;
            }
          ];
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      password_encryption = "scram-sha-256";
    };
    authentication = ''
      # Allow grafana user to connect via local socket with peer auth (no password)
      local   all potgres                                             peer
      local   all ${config.services.grafana.settings.database.user}   peer
      local   all firefly-iii                                         peer
      local   all ${config.services.forgejo.database.user}            peer

      # Require SCRAM password for admin on local socket and TCP (IPv4 + IPv6)
      local   all             admin                                   scram-sha-256
      host    all             admin           127.0.0.1/32            scram-sha-256
      host    all             admin           ::1/128                 scram-sha-256

      # Optionally block all other users from connecting unless explicitly configured
      # local   all             all                                     reject
      # host    all             all             all                     reject
    '';
    ensureDatabases = [
      "firefly-iii"
      config.services.grafana.settings.database.name
      config.services.forgejo.database.name
    ];
    ensureUsers = [
      {
        name = "admin";
        ensureClauses = {
          superuser = true;
          login = true;
          createrole = true;
          createdb = true;
        };
      }
      {
        name = config.services.grafana.settings.database.user;
        ensureDBOwnership = true;
      }
      {
        name = "firefly-iii";
        ensureDBOwnership = true;
      }
      {
        name = config.services.forgejo.database.user;
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.postgresql.postStart = lib.mkAfter ''
    $PSQL -f ${pkgs.writeText "postgresql-post-init.sql" ''
      ALTER USER admin WITH PASSWORD 'SCRAM-SHA-256$4096:4ASEVqDlBNdjM7PKDkIYXg==$Y0n8toSrM6lgAzASCTCVq+UzxVEc3ANMCPYfEarQs88=:yVyYyjmUqUoLe26EXSQE4Zvo7B3me+3HcelupObpFf4=';
    ''}
  '';

  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    compressionLevel = 11;
    backupAll = true;
  };

  services.pgadmin = {
    enable = true;
    openFirewall = true;
    initialEmail = "t@tsandrini.sh";
    initialPasswordFile = config.age.secrets."hosts/${hostName}/pgadmin-admin-password".path;
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "NixOS-node-exporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
      {
        job_name = "${hostName}_prometheus";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.port}" ];
          }
        ];
      }
      {
        job_name = "${hostName}_postgres";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.postgres.port}" ];
          }
        ];
      }
      {
        job_name = "${hostName}_nginx";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
          }
        ];
      }
      {
        job_name = "${hostName}_nginxlog";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.nginxlog.port}" ];
          }
        ];
      }
    ];
  };

  services.prometheus.exporters = {
    postgres = {
      enable = true;
      runAsLocalSuperUser = true;
    };

    nginx = {
      enable = true;
      scrapeUri = "http://127.0.0.1/nginx_status";
    };

    nginxlog = {
      enable = true;
      inherit (config.services.nginx) group;
      settings.namespaces = [
        {
          format = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\"";
          metrics_override.prefix = "nginx";
          source_files = [ "/var/log/nginx/access.log" ];
        }
      ];
    };
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

    "hosts/${hostName}/pgadmin-admin-password" = {
      file = "${secretsPath}/hosts/${hostName}/pgadmin-admin-password.age";
    };

    "hosts/${hostName}/wg-home-tunnel-privkey" = {
      file = "${secretsPath}/hosts/${hostName}/wg-home-tunnel-privkey.age";
    };

    # "hosts/${hostName}/firefly-iii-app-key" = {
    #   file = "${secretsPath}/hosts/${hostName}/firefly-iii-app-key.age";
    #   owner = config.services.firefly-iii.user;
    # };
  };
}
