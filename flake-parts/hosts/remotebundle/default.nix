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
{
  inputs,
  secretsPath,
  infraVars,
}:
{
  pkgs,
  config,
  system,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
  immutable-insights = inputs.immutable-insights.packages.${system}.default;

  # --- database ---
  postgresVars = selfVars.services.postgresql;
  pgadminVars = selfVars.services.pgadmin;

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  grafanaVars = monitoringVars.services.grafana;
  lokiVars = monitoringVars.services.loki;
  prometheusVars = monitoringVars.services.prometheus;
  prometheusExporters = monitoringVars.services.prometheus.exporters;

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;

  # --- forgejo ---
  forgejoVars = infraVars.hosts."remotebundle".services.forgejo;

  # --- immich ---
  immichVars = infraVars.hosts."remotebundle".services.immich;

  # --- prometheus exporters ---
  mailserverExporters = infraVars.hosts."remotebundle".services.prometheus.exporters;

  certbotWedosHomeEnv = pkgs.python3.withPackages (ps: [
    inputs.self.packages.${system}.certbot-dns-wedos
    ps.certbot
  ]);
  certbotWedosCertDir = "/var/lib/certbot-wedos-home/config/live";

  mkIntraVhost =
    attrs:
    {
      listen = [
        {
          addr = selfVars.wgAddress;
          port = 443;
          ssl = true;
        }
        {
          addr = selfVars.wgAddress;
          port = 80;
        }
      ];
      forceSSL = true;
      sslCertificate = "${certbotWedosCertDir}/${nginxVars.intranetDomain}/fullchain.pem";
      sslCertificateKey = "${certbotWedosCertDir}/${nginxVars.intranetDomain}/privkey.pem";

      extraConfig = ''
        allow 10.0.33.0/24;
        allow 10.10.0.0/24;
        deny all;
      '';
    }
    // attrs;
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
    (inputs.vpsadminos + "/os/lib/nixos-container/unstable/vpsadminos.nix")
    (inputs.nix-mineral + "/nix-mineral.nix")

    ./nm-overrides.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ ];

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

  # NAS
  fileSystems."/mnt/NAS" = {
    device = "172.16.131.12:/nas/5829";
    fsType = "nfs";
    options = [ "nofail" ];
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

  nix-mineral.enable = true;

  security.sudo.extraRules = [
    {
      users = [ "tsandrini" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  tensorfiles.networking.firewall.subnets-firewall = {
    enable = true;
    subnets = {
      "${infraVars.common.networking.defaultSubnet}" = {
        allowedTCPPorts = [ ];
      };
      "${infraVars.common.networking.intranetSubnet}" = {
        allowedTCPPorts = [ ];
      };
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      config.networking.wireguard.interfaces.wg-home-tunnel.listenPort
    ];
  };

  networking.wireguard.interfaces = {
    wg-home-tunnel = {
      ips = [ "${selfVars.wgAddress}/32" ];
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

    virtualHosts."${nginxVars.primaryDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.immutable-insights.settings.BIND}";
      };
    };

    virtualHosts."upstream-${nginxVars.primaryDomain}" = {
      serverName = nginxVars.primaryDomain;
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

    virtualHosts."${virtualHostsVar."grafana".domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.grafana.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."pgadmin".domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.pgadmin.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."forgejo".domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.forgejo.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."prometheus".domain}" = {
      enableACME = true;
      forceSSL = true;
      basicAuthFile = config.age.secrets."hosts/${hostName}/prometheus-ui-basic-auth-file".path;
      locations."/" = {
        proxyPass = "http://${virtualHostsVar."prometheus".proxyEndpoint}";
      };
    };

    virtualHosts."${virtualHostsVar."immich".domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${virtualHostsVar."immich".proxyEndpoint}";
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };

    # --- HOME intranet ---
    virtualHosts."intra-default-sink" = {
      serverName = "~^(.+)\\.home\\.tsandrini\\.sh$";

      forceSSL = true;
      sslCertificate = "${certbotWedosCertDir}/${nginxVars.intranetDomain}/fullchain.pem";
      sslCertificateKey = "${certbotWedosCertDir}/${nginxVars.intranetDomain}/privkey.pem";

      locations."= /unauthorized.html" = {
        root = "/etc/nginx-static";
        extraConfig = "internal;";
      };

      locations."/" = {
        extraConfig = ''
          error_page 403 /unauthorized.html;
          return 403;
        '';
      };

      extraConfig = ''
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
      '';
    };

    virtualHosts."${virtualHostsVar."intra-pihole".domain}" = mkIntraVhost {
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://${virtualHostsVar."intra-pihole".proxyEndpoint}";
      };
    };
  };

  environment.etc."nginx-static/unauthorized.html".source = ./unauthorized.html;

  services.immich = {
    enable = true;
    inherit (immichVars) port;
    accelerationDevices = null;
    database = {
      enable = true;
      createDB = false;
      host = "/run/postgresql";
      inherit (postgresVars.instances."immich") user;
      name = postgresVars.instances."immich".database;
    };
  };

  # HW acceleration
  users.users."${config.services.immich.user}".extraGroups = [
    "video"
    "render"
  ];

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    database = {
      createDatabase = false;
      type = "postgres";
      socket = "/run/postgresql";
      inherit (postgresVars.instances."forgejo") user;
      name = postgresVars.instances."forgejo".database;
    };
    settings = {
      server = {
        HTTP_PORT = forgejoVars.server.http_port;
        HTTP_ADDR = forgejoVars.server.http_addr;

        ROOT_URL = "https://${virtualHostsVar."forgejo".domain}/";
        DOMAIN = virtualHostsVar."forgejo".domain;
        SSH_PORT = infraVars.common.services.openssh.defaultPort;
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
        PROTOCOL = "smtp";
        SMTP_ADDR = "localhost";
        FROM = "git-bot@$tsandrini.sh";
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
        METRICS_BIND_NETWORK = "tcp";
      };
    };

    instances = {
      immutable-insights = {
        enable = true;
        group = "nginx";
        settings = {
          TARGET = "unix:///run/nginx/nginx.sock";
          METRICS_BIND = "localhost:${toString virtualHostsVar."immutable-insights".anubisMetricsPort}";
        };
      };

      forgejo = {
        enable = true;
        settings = {
          TARGET = "http://${virtualHostsVar."forgejo".proxyEndpoint}";
          METRICS_BIND = "localhost:${toString virtualHostsVar."forgejo".anubisMetricsPort}";
        };
      };

      grafana = {
        enable = true;
        settings = {
          TARGET = "http://${virtualHostsVar."grafana".proxyEndpoint}";
          METRICS_BIND = "localhost:${toString virtualHostsVar."grafana".anubisMetricsPort}";
        };
      };

      pgadmin = {
        enable = true;
        settings = {
          TARGET = "http://${virtualHostsVar."pgadmin".proxyEndpoint}";
          METRICS_BIND = "localhost:${toString virtualHostsVar."pgadmin".anubisMetricsPort}";
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
      security.disable_initial_admin_creation = true;

      security.admin_email = "t@tsandrini.sh";
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
              options.path = ./grafana/dashboards/node-exporter-full.json;
            }
            {
              name = "NGINX by nginxinc";
              options.path = ./grafana/dashboards/nginx-by-nginxinc.json;
            }
            {
              name = "PostgreSQL Database";
              options.path = ./grafana/dashboards/postgresql-database.json;
            }
            # --- Pihole ---
            {
              name = "Pi-hole Exporter";
              options.path = ./grafana/dashboards/pi-hole-exporter.json;
            }
            {
              name = "Pi-hole UI";
              options.path = ./grafana/dashboards/pi-hole-ui.json;
            }
            # --- Logs ---
            {
              name = "Logs / App";
              options.path = ./grafana/dashboards/logs-app.json;
              folder = "Logs & Loki";
            }
            {
              name = "Loki & Promtail";
              options.path = ./grafana/dashboards/loki-and-promtail.json;
            }
            {
              name = "Loki Metrics Dashboard";
              options.path = ./grafana/dashboards/loki-metrics-dashboard.json;
              folder = "Logs & Loki";
            }
            # --- Mailserver ---
            {
              name = "dovecot2 (old_stats) overview by tsandrini";
              options.path = ./grafana/dashboards/dovecot2-old-stats-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
            {
              name = "Postfix";
              options.path = ./grafana/dashboards/postfix.json;
              folder = "Mailserver";
            }
            {
              name = "Postfix overview by tsandrini";
              options.path = ./grafana/dashboards/postfix-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
            {
              name = "Rspamd stat overview by tsandrini";
              options.path = ./grafana/dashboards/rspamd-stat-overview-by-tsandrini.json;
              folder = "Mailserver";
            }
          ];
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      inherit (postgresVars) port;
      password_encryption = "scram-sha-256";
    };
    authentication = ''
      # Allow grafana user to connect via local socket with peer auth (no password)
      local   all potgres                                             peer
      local   all ${postgresVars.instances."grafana".user}            peer
      local   all ${postgresVars.instances."immich".user}             peer
      local   all ${postgresVars.instances."forgejo".user}            peer
      local   all ${postgresVars.instances."firefly-iii".user}        peer

      # Require SCRAM password for admin on local socket and TCP (IPv4 + IPv6)
      local   all             admin                                   scram-sha-256
      host    all             admin           127.0.0.1/32            scram-sha-256
      host    all             admin           ::1/128                 scram-sha-256

      # Optionally block all other users from connecting unless explicitly configured
      # local   all             all                                     reject
      # host    all             all             all                     reject
    '';
    ensureDatabases = [
      postgresVars.instances."grafana".database
      postgresVars.instances."immich".database
      postgresVars.instances."forgejo".database
      postgresVars.instances."firefly-iii".database
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
        name = postgresVars.instances."grafana".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."forgejo".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."firefly-iii".user;
        ensureDBOwnership = true;
      }
      {
        name = postgresVars.instances."immich".user;
        ensureDBOwnership = true;
      }
    ];
  };

  # systemd.services.postgresql.postStart = ''
  #   $PSQL -f ${pkgs.writeText "postgresql-post-init.sql" ''
  #     ALTER USER admin WITH PASSWORD 'SCRAM-SHA-256$4096:4ASEVqDlBNdjM7PKDkIYXg==$Y0n8toSrM6lgAzASCTCVq+UzxVEc3ANMCPYfEarQs88=:yVyYyjmUqUoLe26EXSQE4Zvo7B3me+3HcelupObpFf4=';
  #   ''}
  # '';

  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    compressionLevel = 11;
    backupAll = true;
  };

  services.pgadmin = {
    enable = true;
    inherit (pgadminVars) port;
    initialEmail = "t@tsandrini.sh";
    initialPasswordFile = config.age.secrets."hosts/${hostName}/pgadmin-admin-password".path;
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
          honor_labels = true;
          metrics_path = "/probe";
          params = {
            target = [
              "http://${
                infraVars.hosts."remotebundle".address
              }:${toString mailserverExporters.rspamd.targetPort}/stat"
            ];
          };
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

  systemd.services.certbot-wedos-home = {
    description = "Certbot DNS-01 (WEDOS) for ${nginxVars.intranetDomain} wildcard";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";

      StateDirectory = "certbot-wedos-home";
      StateDirectoryMode = "0750";
      LogsDirectory = "certbot-wedos-home";
      LogsDirectoryMode = "0750";

      User = "root";
      Group = config.services.nginx.group;
      UMask = "0027";
      PrivateTmp = true;
      NoNewPrivileges = true;

      ExecStart = ''
        ${certbotWedosHomeEnv}/bin/certbot certonly \
          --non-interactive --agree-tos \
          --email ${infraVars.common.contacts.securityEmail} \
          --authenticator dns-wedos \
          --dns-wedos-credentials ${config.age.secrets."hosts/${hostName}/wedos-wapi-credentials".path} \
          --dns-wedos-propagation-seconds 450 \
          -d ${nginxVars.intranetDomain} \
          -d "*.${nginxVars.intranetDomain}" \
          --config-dir /var/lib/certbot-wedos-home/config \
          --work-dir /var/lib/certbot-wedos-home/work \
          --logs-dir /var/log/certbot-wedos-home
      '';
    };
  };

  systemd.timers.certbot-wedos-home = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    # allow group traversal down the tree
    "d /var/lib/certbot-wedos-home 0750 root ${config.services.nginx.group} - -"
    "d /var/lib/certbot-wedos-home/config 0750 root ${config.services.nginx.group} - -"
    "d /var/lib/certbot-wedos-home/config/live 0750 root ${config.services.nginx.group} - -"
    "d /var/lib/certbot-wedos-home/config/archive 0750 root ${config.services.nginx.group} - -"
  ];

  services.prometheus.exporters = {
    postgres = {
      enable = true;
      inherit (prometheusExporters.postgres) port;
      runAsLocalSuperUser = true;
    };

    nginx = {
      enable = true;
      inherit (prometheusExporters.nginx) port;
      scrapeUri = "http://127.0.0.1/nginx_status";
    };

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

    nginxlog = {
      enable = true;
      inherit (prometheusExporters.nginxlog) port;
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
    "hosts/${hostName}/wedos-wapi-credentials" = {
      file = "${secretsPath}/hosts/${hostName}/wedos-wapi-credentials.age";
      owner = config.systemd.services.certbot-wedos-home.serviceConfig.User;
    };

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

    "hosts/${hostName}/prometheus-ui-basic-auth-file" = {
      file = "${secretsPath}/hosts/${hostName}/prometheus-ui-basic-auth-file.age";
      owner = config.services.nginx.user;
    };

    # "hosts/${hostName}/firefly-iii-app-key" = {
    #   file = "${secretsPath}/hosts/${hostName}/firefly-iii-app-key.age";
    #   owner = config.services.firefly-iii.user;
    # };
  };
}
