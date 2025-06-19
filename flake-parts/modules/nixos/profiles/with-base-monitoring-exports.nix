# --- flake-parts/modules/nixos/profiles/with-base-monitoring-exports.nix
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
{ localFlake }:
{
  config,
  hostName,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    optional
    mkMerge
    mkEnableOption
    mkOption
    ;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.with-base-monitoring-exports;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.with-base-monitoring-exports = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the with-base-monitoring-exports system profile.

      Assuming there is a general monitoring server, this profile sets up basic logging
      and reporting for this server.
    '';

    promtail = {
      enable =
        mkEnableOption ''
          Enables the Promtail service.
        ''
        // {
          default = true;
        };

      # TODO: maybe create infraVars?
      clientUrl = mkOption {
        type = types.str;
        default = "http://localhost:3031/loki/api/v1/push";
        description = ''
          The URL of the Loki server to which Promtail will send logs.
        '';
      };
    };

    prometheus = {
      exporters = {
        node = {
          enable =
            mkEnableOption ''
              Enables the Prometheus Node Exporter.
            ''
            // {
              default = true;
            };

          openFirewall = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to open the firewall for the Node Exporter port.
            '';
          };

          port = mkOption {
            type = types.int;
            default = 9002;
            description = ''
              The port on which the Node Exporter will listen for
              Prometheus scrape requests.
            '';
          };

        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.promtail.enable {
      services.promtail = {
        enable = _ true;
        configuration = {
          server = {
            # 0 disables the servers
            http_listen_port = _ 0;
            grpc_listen_port = _ 0;
          };
          positions = {
            filename = _ "/tmp/promtail-positions.yaml";
          };
          clients = [
            {
              url = cfg.promtail.clientUrl;
            }
          ];
          scrape_configs = [
            {
              job_name = "journal";
              journal = {
                max_age = "12h"; # How far back to read from the journal on startup.
                labels = {
                  job = "systemd-journal";
                  host = hostName;
                  app_group = "NixOS";
                };
              };
              relabel_configs = [
                {
                  source_labels = [ "__journal__systemd_unit" ];
                  target_label = "systemd_unit";
                }
                {
                  source_labels = [ "__journal__syslog_identifier" ];
                  target_label = "syslog_identifier";
                }
              ];
            }
          ];
        };
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.prometheus.exporters.node.enable {
      networking.firewall.allowedTCPPorts = optional cfg.prometheus.exporters.node.openFirewall config.services.prometheus.exporters.node.port;

      services.prometheus.exporters.node = {
        enable = _ true;
        enabledCollectors = [
          "conntrack"
          "cpu"
          "diskstats"
          "filesystem"
          "meminfo"
          "netdev"
          "pressure"
          "rapl"
          "sysctl"
          "systemd"
        ];
        port = _ cfg.prometheus.exporters.node.port;
      };
    })
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
