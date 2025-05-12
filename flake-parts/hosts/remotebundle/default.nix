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
  fireflyDomain = "firefly.${domain}";
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
    profiles.headless.enable = true;
    profiles.packages-base.enable = true;
    # profiles.packages-extra.enable = true;

    services.mailserver.enable = true;
    services.mailserver.roundcube.enable = true;
    services.mailserver.rspamd-ui.enable = true;

    services.monit = {
      enable = true;
      alertAddress = "monitoring@${domain}";
      mailserver.enable = true;
      checks = {
        filesystem.root.enable = false;
        system.enable = true;
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

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;
    tasks.system-autoupgrade.enable = false;

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

  programs.bash = {
    interactiveShellInit = lib.mkBefore ''
      ${lib.getExe pkgs.microfetch}
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  systemd.extraConfig = ''
    DefaultTimeoutStartSec=900s
  '';

  users.users.nginx.extraGroups = [
    config.users.groups.anubis.name
  ];

  services.fail2ban.jails = {
    # Auth failures - moderate risk of false positives
    nginx-http-auth.settings = {
      enabled = true;
      maxretry = 5;
      bantime = "10m";
      findtime = "3m";
    };

    # Rate limiting - medium-high risk of false positives
    nginx-limit-req.settings = {
      enabled = true;
      maxretry = 3;
      findtime = "1m";
      bantime = "30m";
    };

    # Bad requests - low-medium risk of false positives
    nginx-bad-request.settings = {
      enabled = true;
      maxretry = 3;
      findtime = "1m";
      bantime = "1h";
    };

    # Bot scanning - very low risk of false positives
    nginx-botsearch.settings = {
      enabled = true;
      maxretry = 10;
      findtime = "2m";
      bantime = "2h";
    };

    # Forbidden access - low risk of false positives
    nginx-forbidden.settings = {
      enabled = true;
      maxretry = 5;
      findtime = "2m";
      bantime = "2h";
    };

    grafana.settings = {
      enabled = true;
    };
    roundcube.settings = {
      enabled = true;
    };
  };

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

    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances."".settings.BIND}";
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
        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      };
    };

    virtualHosts."${pgadminDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.pgadmin.port}";
      };
    };

    virtualHosts."${forgejoDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
      };
    };

    virtualHosts."${fireflyDomain}" = {
      enableACME = true;
      forceSSL = true;
    };
  };

  # Add firefly-pico and firefly-importer

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

  services.firefly-iii = {
    enable = true;
    virtualHost = fireflyDomain;
    enableNginx = true;
    settings = {
      APP_KEY_FILE = config.age.secrets."hosts/${hostName}/firefly-iii-app-key".path;
      APP_URL = "https://${config.services.firefly-iii.virtualHost}";
      DB_CONNECTION = "pgsql";
      DB_HOST = "/run/postgresql";
      SITE_OWNER = "t@${domain}";
      TZ = "Europe/Prague";
    };
  };

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
    instances."" = {
      # TODO update name
      enable = true;
      group = "nginx";
      settings = {
        TARGET = "unix:///run/nginx/nginx.sock";
        SERVE_ROBOTS_TXT = true;
      };
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
          name = "Prometheus";
          type = "prometheus";
          uid = "local_prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "Dashboards";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  environment.etc = {
    "grafana-dashboards/node.json" = {
      user = "grafana";
      group = "grafana";
      source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
        sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
      };
    };
    "grafana-dashboards/nginx.json" = {
      user = "grafana";
      group = "grafana";
      source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/14900/revisions/2/download";
        sha256 = "sha256-9iOEwKdFxOyw2T7Non4k2yUwiajWpH3qgQTyJRrttwM=";
      };
    };
    # "grafana-dashboards/postgres.json" = {
    #   user = "grafana";
    #   group = "grafana";
    #   source = pkgs.fetchurl {
    #     url = "https://grafana.com/api/dashboards/9628/revisions/7/download";
    #     sha256 = "sha256-xkzDitnr168JVR7oPmaaOPYqdufICSmvVmilhScys3Y=";
    #   };
    "grafana-dashboards/loki.json" = {
      user = "grafana";
      group = "grafana";
      source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/14055/revisions/5/download";
        sha256 = "sha256-9vfUGpypFNKm9T1F12Cqh8TIl0x3jSwv2fL9HVRLt3o=";
      };
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

  services.pgadmin = {
    enable = true;
    openFirewall = true;
    initialEmail = "t@tsandrini.sh";
    initialPasswordFile = config.age.secrets."hosts/${hostName}/pgadmin-admin-password".path;
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "sysctl"
          "diskstats"
          "netdev"
          "cpu"
          "filesystem"
        ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "${hostName}-node-exporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "0.0.0.0"; # Listen on all interfaces
      };
      auth_enabled = false;

      common = {
        instance_addr = "127.0.0.1";
        ring = {
          kvstore = {
            store = "inmemory"; # Use inmemory instead of Consul
          };
        };
      };

      ingester = {
        lifecycler = {
          address = "0.0.0.0";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "2h";
        max_chunk_age = "2h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from = "2023-04-29";
            index = {
              period = "24h";
              prefix = "index_";
            };
            object_store = "filesystem";
            schema = "v13";
            store = "tsdb";
          }
        ];
      };

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      query_scheduler = {
        max_outstanding_requests_per_tenant = 32768;
        # Remove Consul dependency - use in-memory store
        scheduler_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };

      querier = {
        max_concurrent = 16;
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        delete_request_store = "filesystem";
        delete_request_cancel_period = "24h";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };

      # Add explicit configuration for distributor to use inmemory store
      distributor = {
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              app = "promtail";
              host = hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };

  systemd.services.promtail.after = [ "loki.service" ];
  systemd.services.promtail.requires = [ "loki.service" ];

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

    "hosts/${hostName}/firefly-iii-app-key" = {
      file = "${secretsPath}/hosts/${hostName}/firefly-iii-app-key.age";
      owner = config.services.firefly-iii.user;
    };
  };
}
