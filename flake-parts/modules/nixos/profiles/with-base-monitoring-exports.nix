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
{ localFlake, infraVars }:
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

    alloy = {
      enable =
        mkEnableOption ''
          Enables the Grafana Alloy service for log forwarding to Loki.
        ''
        // {
          default = true;
        };

      clientUrl = mkOption {
        type = types.str;
        default = "http://${
          if hostName == "remotebundle" then "localhost" else infraVars.hosts."remotebundle".wgAddress
        }:${toString infraVars.hosts."remotebundle".services.loki.server.http_port}/loki/api/v1/push";
        description = ''
          The URL of the Loki server to which Alloy will send logs.
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

          # openFirewall = mkOption {
          #   type = types.bool;
          #   default = false;
          #   description = ''
          #     Whether to open the firewall for the Node Exporter port.
          #   '';
          # };

          port = mkOption {
            type = types.int;
            default = infraVars.common.services.prometheus.exporters.node.defaultPort;
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
    (mkIf cfg.alloy.enable {
      services.alloy.enable = _ true;

      environment.etc."alloy/config.alloy".text = ''
        loki.relabel "journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "systemd_unit"
          }

          rule {
            source_labels = ["__journal__syslog_identifier"]
            target_label  = "syslog_identifier"
          }
        }

        loki.source.journal "journal" {
          max_age       = "12h"
          relabel_rules = loki.relabel.journal.rules
          forward_to    = [loki.write.default.receiver]
          labels        = {
            job       = "systemd-journal",
            host      = "${hostName}",
            app_group = "NixOS",
          }
        }

        loki.write "default" {
          endpoint {
            url = "${cfg.alloy.clientUrl}"
          }
        }
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.prometheus.exporters.node.enable {
      tensorfiles.networking.firewall.subnets-firewall = {
        defaultSubnets = {
          allowedTCPPorts = [ cfg.prometheus.exporters.node.port ];
        };
      };

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
