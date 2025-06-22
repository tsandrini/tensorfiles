# --- flake-parts/modules/nixos/services/monitoring.loki.nix
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
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.services.monitoring.loki;
  _ = mkOverrideAtModuleLevel;
in
{
  options.tensorfiles.services.monitoring.loki = {
    enable = mkEnableOption ''
      Enables default configuration for the Loki service.
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.loki = {
        enable = _ true;
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
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
