# --- flake-parts/hosts/remotebundle/parts/nginx-proxy.nix
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
  config,
  system,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
  immutable-insights = inputs.immutable-insights.packages.${system}.default;

  # --- monitoring ---
  monitoringVars = infraVars.hosts."remotebundle";
  prometheusExporters = monitoringVars.services.prometheus.exporters;

  # --- nginx ---
  nginxVars = infraVars.hosts."remotebundle".services.nginx;
  virtualHostsVar = nginxVars.virtualHosts;

  mkIntraVhost =
    attrs:
    (
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
        useACMEHost = nginxVars.intranetDomain;

        extraConfig = ''
          allow ${infraVars.common.networking.defaultSubnet};
          allow ${infraVars.common.networking.intranetSubnet};
          deny all;
        '';
      }
      // attrs
    );

  # NOTE: HTTP/3 advertised to clients via Alt-Svc; ma=86400 is the cache
  # lifetime — see RFC 7838. Toggling h3 off later would strand clients with
  # this hint until it expires, so keep h3 on once enabled.
  mkPublicVhost =
    attrs:
    (
      {
        enableACME = true;
        forceSSL = true;
        quic = true;
        http3 = true;
        extraConfig = ''
          add_header Alt-Svc 'h3=":443"; ma=86400' always;
        '';
      }
      // attrs
    );
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

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443 # HTTP/3 / QUIC
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        #
      ];
    };
  };

  users.users.nginx.extraGroups = [
    config.users.groups.anubis.name
  ];

  security.acme = {
    acceptTerms = true;

    defaults = {
      email = infraVars.common.contacts.securityEmail;
      dnsProvider = "wedos";
      dnsResolver = "ns.wedos.net:53";
      environmentFile = config.age.secrets."hosts/${hostName}/wedos-acme-env".path;
      dnsPropagationCheck = true;
    };

    certs."${nginxVars.intranetDomain}" = {
      inherit (config.services.nginx) group;
      domain = nginxVars.intranetDomain;
      extraDomainNames = [ "*.${nginxVars.intranetDomain}" ];
      reloadServices = [ "nginx.service" ];
    };
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    # NOTE: needed so QUIC connection IDs stay routed to the right worker
    # across reloads and multi-worker setups.
    enableQuicBPF = true;

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

    virtualHosts."${nginxVars.primaryDomain}" = mkPublicVhost {
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.immutable-insights.settings.BIND}";
      };
    };

    virtualHosts."www.${nginxVars.primaryDomain}" = mkPublicVhost {
      globalRedirect = nginxVars.primaryDomain;
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

    virtualHosts."${virtualHostsVar."grafana".domain}" = mkPublicVhost {
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.grafana.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."pgadmin".domain}" = mkPublicVhost {
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.pgadmin.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."forgejo".domain}" = mkPublicVhost {
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://unix:${config.services.anubis.instances.forgejo.settings.BIND}";
      };
    };

    virtualHosts."${virtualHostsVar."prometheus".domain}" = mkPublicVhost {
      basicAuthFile = config.age.secrets."hosts/${hostName}/prometheus-ui-basic-auth-file".path;
      locations."/" = {
        proxyPass = "http://${virtualHostsVar."prometheus".proxyEndpoint}";
      };
    };

    virtualHosts."${virtualHostsVar."immich".domain}" = mkPublicVhost {
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
      useACMEHost = nginxVars.intranetDomain;
      root = inputs.self.packages.${system}.intranet-unauthorized;

      locations."= /index.html" = {
        extraConfig = "internal;";
      };

      locations."/" = {
        extraConfig = ''
          error_page 403 /index.html;
          return 403;
        '';
      };

      locations."/assets/" = {
        extraConfig = ''
          expires -1;
        '';
      };

      extraConfig = ''
        etag off;
        if_modified_since off;
        add_header Last-Modified "" always;

        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        add_header Clear-Site-Data '"cache"' always;
      '';
    };

    virtualHosts."${virtualHostsVar."intra-pihole".domain}" = mkIntraVhost {
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://${virtualHostsVar."intra-pihole".proxyEndpoint}";
      };
    };
  };

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

  services.prometheus.exporters = {
    nginx = {
      enable = true;
      inherit (prometheusExporters.nginx) port;
      scrapeUri = "http://127.0.0.1/nginx_status";
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
    "hosts/${hostName}/wedos-acme-env" = {
      file = "${secretsPath}/hosts/${hostName}/wedos-acme-env.age";
    };

    "hosts/${hostName}/prometheus-ui-basic-auth-file" = {
      file = "${secretsPath}/hosts/${hostName}/prometheus-ui-basic-auth-file.age";
      owner = config.services.nginx.user;
    };
  };
}
