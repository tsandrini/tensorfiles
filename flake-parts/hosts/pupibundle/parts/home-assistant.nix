# --- flake-parts/hosts/pupibundle/parts/home-assistant.nix
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
# Home Assistant (meta/plans/home-assistant/spec.md). Nix owns the package,
# the unit and configuration.yaml; whatever HA edits at runtime (core
# config, integrations, devices, dashboards, automations) lives in
# /var/lib/hass and is backed up by HA. Intranet only: HA binds loopback and
# nginx serves it on the LAN address with the `*.home` wildcard cert to the
# home and WireGuard subnets.
{
  inputs,
  secretsPath,
  infraVars,
}:
{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
let
  inherit (lib) mkIf mkMerge;

  selfVars = infraVars.hosts."${hostName}";
  nginxVars = infraVars.hosts."blehbundle".services.nginx;
  vhost = selfVars.services.nginx.virtualHosts."intra-ha";

  wedosEnv = "hosts/${hostName}/wedos-acme-env";
  tlsCheck = builtins.pathExists "${secretsPath}/${wedosEnv}.age";

  # UI-editable files that configuration.yaml `!include`s; HA does not create them
  uiIncludes = {
    automation = "automations.yaml";
    scene = "scenes.yaml";
    script = "scripts.yaml";
  };
in
{
  # NOTE: module and package from the root nixpkgs: Hydra-cached, unlike the
  # module's default package (`doInstallCheck = false`), and HA keeps up with
  # unstable instead of the Pi's release pin; never override the package
  disabledModules = [ "services/home-automation/home-assistant.nix" ];
  imports = [ "${inputs.nixpkgs}/nixos/modules/services/home-automation/home-assistant.nix" ];

  config = mkMerge [
    # |----------------------------------------------------------------------| #
    {
      warnings = lib.optional (!tlsCheck) "home-assistant: ${wedosEnv}.age is missing, no TLS vhost.";

      services.home-assistant = {
        enable = true;
        package = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.home-assistant;

        # NOTE: integrations set up in the UI; those named in `config` below
        # are added by the module
        extraComponents = [
          # onboarding wizard, https://wiki.nixos.org/wiki/Home_Assistant
          "analytics"
          "google_translate"
          "met"
          "radio_browser"
          "shopping_list"
          "isal"

          "rpi_power"
          "tplink" # Tapo L530 bulbs, local KLAP API
          "ntfy"
        ];

        config = {
          # NOTE: any core key in YAML (the module injects time_zone) locks the whole
          # core config in the UI; the wizard owns it, keeping coordinates out of git
          homeassistant.time_zone = null;

          # NOTE: no `http` block: since 2026.9 HA keeps it in .storage (loopback
          # bind, proxy trust; Settings → System → Network) and ignores YAML
          default_config = { };
          recorder.purge_keep_days = 30;
          prometheus = { };
        }
        // lib.mapAttrs' (domain: file: lib.nameValuePair "${domain} ui" "!include ${file}") uiIncludes;
      };

      systemd.tmpfiles.rules = lib.mapAttrsToList (
        _: file: "f ${config.services.home-assistant.configDir}/${file} 0644 hass hass - -"
      ) uiIncludes;
    }
    # |----------------------------------------------------------------------| #
    (mkIf tlsCheck {
      services.nginx = {
        enable = true;
        # NOTE: port 80 belongs to pihole-FTL's web server; TLS only
        virtualHosts."${vhost.domain}" = {
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
          locations."/" = {
            proxyPass = "http://${vhost.proxyEndpoint}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            # NOTE: the frontend and the companion app hold /api/websocket open
            # for hours; backup uploads (restore) are hundreds of MB
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 1h;
              proxy_send_timeout 1h;
              client_max_body_size 2g;
            '';
          };
        };
      };
    })
    # |----------------------------------------------------------------------| #
  ];
}
