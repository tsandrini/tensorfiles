# --- flake-parts/hosts/pupibundle/parts/ccdash-hub.nix
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
#
# The ccdash hub (meta/plans/ccdash-hub/spec.md): every workstation's
# collector reports here over `wss://ccdash.home.tsandrini.sh/collect`; the
# web UI (installable as a PWA), the API and the Web Push notifications
# are served from here (ntfy lost the trial; `ntfy = true` in the infra
# variables would bring it back). Intranet only: nginx listens on the LAN
# address with the `*.home` wildcard cert and allows the home and WireGuard
# subnets. Each piece waits for its secret.
{
  inputs,
  secretsPath,
  infraVars,
}:
{
  config,
  lib,
  hostName,
  ...
}:
let
  inherit (builtins) pathExists;
  inherit (lib) mkIf mkMerge optionalAttrs;

  selfVars = infraVars.hosts."${hostName}";
  hubVars = selfVars.services.ccdash-hub;
  nginxVars = infraVars.hosts."blehbundle".services.nginx;
  vhost = selfVars.services.nginx.virtualHosts."intra-ccdash";

  secret = name: "${secretsPath}/${name}.age";
  uiToken = "hosts/${hostName}/ccdash-ui-token";
  wedosEnv = "hosts/${hostName}/wedos-acme-env";
  ntfyToken = "common/ccdash-ntfy-token";
  collectorToken = host: "common/ccdash-collector-token-${host}";
  collectors = builtins.filter (host: pathExists (secret (collectorToken host))) hubVars.collectors;

  hubCheck = pathExists (secret uiToken);
  tlsCheck = pathExists (secret wedosEnv);
  ntfyCheck = hubVars.ntfy && pathExists (secret ntfyToken);
in
{
  imports = [ inputs.ccdash.nixosModules.hub ];

  config = mkMerge [
    # |----------------------------------------------------------------------| #
    {
      warnings =
        lib.optional (!hubCheck) "ccdash hub: ${uiToken}.age is missing, the hub stays off."
        ++ lib.optional (!tlsCheck) "ccdash hub: ${wedosEnv}.age is missing, no TLS vhost.";
    }
    # |----------------------------------------------------------------------| #
    (mkIf hubCheck {
      services.ccdash-hub = {
        enable = true;
        # NOTE: x86_64 derivations (cross-compiled hub, static panel), built by
        # the deploying machine (deploy-rs `remoteBuild = false`)
        package = inputs.ccdash.packages.x86_64-linux.ccdash-aarch64-linux;
        webPackage = inputs.ccdash.packages.x86_64-linux.ccdash-web;
        inherit (hubVars) port;
        tokenFile = config.age.secrets."${uiToken}".path;
        collectors = lib.genAttrs collectors (host: config.age.secrets."${collectorToken host}".path);
        nginx = {
          enable = tlsCheck;
          inherit (vhost) domain;
        };
        backup.enable = true;
        settings = {
          host = hostName;
          store.retention_days = 90;
          workspaces.dirs = map (w: "/home/tsandrini/ProjectBundle/${w}") [
            "meteopress"
            "PesekMudra"
            "tsandrini"
          ];
          push.subject = "mailto:${infraVars.common.contacts.securityEmail}";
        }
        // optionalAttrs ntfyCheck {
          notify = {
            url = "https://${nginxVars.virtualHosts."intra-ntfy".domain}";
            topic = "ccdash";
            token_file = config.age.secrets."${ntfyToken}".path;
          };
        };
      };

      tensorfiles.services.backup.restic.paths = [ config.services.ccdash-hub.backup.directory ];

      age.secrets = {
        "${uiToken}" = {
          file = secret uiToken;
          owner = "ccdash";
        };
      }
      // optionalAttrs ntfyCheck {
        "${ntfyToken}" = {
          file = secret ntfyToken;
          owner = "ccdash";
        };
      }
      // lib.genAttrs (map collectorToken collectors) (name: {
        file = secret name;
        owner = "ccdash";
      });
    })
    # |----------------------------------------------------------------------| #
    (mkIf (hubCheck && tlsCheck) {
      # NOTE: port 80 belongs to pihole-FTL's web server; TLS only
      services.nginx.virtualHosts."${vhost.domain}" = {
        listen = [
          {
            addr = selfVars.address;
            port = 443;
            ssl = true;
          }
        ];
        onlySSL = true;
        useACMEHost = nginxVars.intranetDomain;
        extraConfig = ''
          allow ${infraVars.common.networking.defaultSubnet};
          allow ${infraVars.common.networking.intranetSubnet};
          deny all;
        '';
      };
    })
    # |----------------------------------------------------------------------| #
  ];
}
