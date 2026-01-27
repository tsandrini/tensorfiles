# --- flake-parts/infra-vars/variables.nix
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
_: rec {
  # TODO: We could decouple this into multiple separate flakeModule options,
  #       but is that worth it? We can still do that in the future
  #       if we need to so its not a big deal.
  common = {
    contacts = {
      securityEmail = "security@tsandrini.sh";
      contactEmail = "t@tsandrini.sh";
      monitoringEmail = "monitoring@tsandrini.sh";
    };
    networking = {
      defaultSubnet = "10.10.0.0/24";
      intranetSubnet = "10.0.33.0/24";
      defaultGateway = "10.10.0.1";
      defaultNameservers = [
        "10.10.0.10"
        "8.8.8.8"
        "8.8.4.4"
        "1.1.1.1"
      ];
    };
    services = {
      openssh = {
        defaultPort = 2222;
      };
      promtail = {
        defaultPort = 3031;
      };
      prometheus = {
        defaultPort = 9090;
        exporters = {
          node = {
            defaultPort = 9100;
          };
          anubis = {
            portRangeStart = 26000;
          };
        };
      };
    };
  };
  hosts = {
    # ----------------------------------
    "remotebundle" =
      let
        address = "localhost";
      in
      {
        inherit address;
        publicAddress = "37.205.15.242";
        wgAddress = "10.0.33.13";
        users = {
          root = { };
          tsandrini = { };
        };
        services = {
          immich = {
            port = 2283;
          };
          grafana = {
            server = {
              http_port = 3001;
              http_addr = "0.0.0.0";
            };
          };
          influxdb2 = {
            server = {
              http_port = 8086;
              http_addr = "localhost";
            };
          };
          loki = {
            server = {
              http_port = 3200;
              http_addr = "0.0.0.0";
            };
          };
          promtail = {
            server = {
              http_port = 3031;
              grpc_port = 0;
            };
          };
          prometheus = {
            server = {
              http_port = 9090;
              http_addr = "localhost";
            };
            exporters = {
              node.port = common.services.prometheus.exporters.node.defaultPort;
              postgres.port = 9187;
              nginx.port = 9113;
              loki.port = hosts."remotebundle".services.loki.server.http_port;
              nginxlog.port = 9117;
              postfix.port = 9154;
              rspamd = {
                port = 7980;
                targetPort = 11334;
              };
              dovecot.port = 9166;
            };
          };
          postgresql = {
            port = 5432;
            instances = {
              # NOTE: The user and database names need to be uqual for
              #       ensureDBOwnership to work
              "grafana" = {
                database = "grafana";
                user = "grafana";
              };
              "forgejo" = {
                database = "forgejo";
                user = "forgejo";
              };
              "immich" = {
                database = "immich";
                user = "immich";
              };
              "firefly-iii" = {
                database = "firefly-iii";
                user = "firefly-iii";
              };
              "hass" = {
                database = "hass";
                user = "hass";
              };
            };
          };
          pgadmin = {
            port = 5050;
          };
          forgejo = {
            server = {
              http_port = 3000;
              http_addr = "localhost";
            };
          };
          nginx =
            let
              inherit (common.services.prometheus.exporters.anubis) portRangeStart;
              primaryDomain = "tsandrini.sh";
              intranetDomain = "home.${primaryDomain}";
            in
            {
              inherit primaryDomain intranetDomain;
              virtualHosts = {
                "immutable-insights" = {
                  domain = "${primaryDomain}";
                  anubisMetricsPort = portRangeStart + 0;
                };
                "pgadmin" = {
                  domain = "pgadmin.${primaryDomain}";
                  proxyEndpoint = "${address}:${toString hosts."remotebundle".services.pgadmin.port}";
                  anubisMetricsPort = portRangeStart + 1;
                };
                "grafana" = {
                  domain = "grafana.${primaryDomain}";
                  proxyEndpoint = "${hosts."remotebundle".address}:${
                    toString hosts."remotebundle".services.grafana.server.http_port
                  }";
                  anubisMetricsPort = portRangeStart + 2;
                };
                "forgejo" = {
                  domain = "git.${primaryDomain}";
                  proxyEndpoint = "${hosts."remotebundle".address}:${
                    toString hosts."remotebundle".services.forgejo.server.http_port
                  }";
                  anubisMetricsPort = portRangeStart + 3;
                };
                "prometheus" = {
                  domain = "prometheus.${primaryDomain}";
                  proxyEndpoint = "${hosts."remotebundle".address}:${
                    toString hosts."remotebundle".services.prometheus.server.http_port
                  }";
                };
                "immich" = {
                  domain = "pics.${primaryDomain}";
                  proxyEndpoint = "${hosts."remotebundle".address}:${
                    toString hosts."remotebundle".services.immich.port
                  }";
                };
                "intra-pihole" = {
                  domain = "pihole.${intranetDomain}";
                  proxyEndpoint = "${hosts."pupibundle".address}";
                };
              };
            };
        };
      };
    # ----------------------------------
    "pupibundle" =
      let
        address = "10.10.0.10";
      in
      {
        inherit address;
        users = {
          root = { };
          tsandrini = { };
        };
        services = {
          unbound = {
            port = 5335;
          };
          prometheus = {
            exporters = {
              node.port = common.services.prometheus.exporters.node.defaultPort;
              pihole.port = 9617;
              unbound.port = 9167;
            };
          };
        };
      };
    # ----------------------------------
  };
}
