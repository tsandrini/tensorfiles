# --- flake-parts/hosts/pupibundle/parts/zigbee.nix
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
# Zigbee (meta/plans/home-assistant/spec.md, "Zigbee"): Zigbee2MQTT on the
# SONOFF Dongle Plus MG24 and a loopback-only mosquitto shared with HA's
# `mqtt` integration (MQTT discovery). The network parameters are pinned
# here; the network key and the frontend token come from an agenix YAML in
# Z2M's state dir, and the whole stack waits for it. The frontend is served
# by nginx on the LAN address with the `*.home` cert to the home and
# WireGuard subnets.
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
  inherit (builtins) pathExists;
  inherit (lib) mkIf mkMerge;

  selfVars = infraVars.hosts."${hostName}";
  nginxVars = infraVars.hosts."blehbundle".services.nginx;
  mqttPort = selfVars.services.mosquitto.port;
  vhost = selfVars.services.nginx.virtualHosts."intra-z2m";

  secret = name: "${secretsPath}/${name}.age";
  z2mSecret = "hosts/${hostName}/zigbee2mqtt-secret.yaml";
  wedosEnv = "hosts/${hostName}/wedos-acme-env";

  zigbeeCheck = pathExists (secret z2mSecret);
  tlsCheck = pathExists (secret wedosEnv);

  dongle = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_16cb664b3af5ef11af67a0a29ed47d52-if00-port0";
in
{
  config = mkMerge [
    # |----------------------------------------------------------------------| #
    {
      warnings =
        lib.optional (!zigbeeCheck) "zigbee: ${z2mSecret}.age is missing, the stack stays off."
        ++ lib.optional (!tlsCheck) "zigbee: ${wedosEnv}.age is missing, no TLS vhost.";
    }
    # |----------------------------------------------------------------------| #
    (mkIf zigbeeCheck {
      services.mosquitto = {
        enable = true;
        listeners = [
          {
            address = "127.0.0.1";
            port = mqttPort;
            # NOTE: anonymous only while loopback is the sole listener
            omitPasswordAuth = true;
            settings.allow_anonymous = true;
            acl = [ "pattern readwrite #" ];
          }
        ];
      };

      services.zigbee2mqtt = {
        enable = true;
        # NOTE: ≥ 2.14 for the SNZB-02DR2 (the Pi's release pin has 2.12.1);
        # Hydra-cached like HA, the module is the same in both sets
        package = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zigbee2mqtt;
        settings = {
          # NOTE: re-copied at every start; below Z2M's settings version
          # (`CURRENT_VERSION`, dist/util/settings.js) it re-migrates each time
          version = 5;
          homeassistant.enabled = true;
          mqtt.server = "mqtt://127.0.0.1:${toString mqttPort}";
          serial = {
            port = dongle;
            adapter = "ember";
            baudrate = 115200;
            rtscts = false;
          };
          advanced = {
            # NOTE: never GENERATE (a new network at every start, see above);
            # changing any of these means re-pairing every device
            channel = 20;
            pan_id = 29630; # 0x73BE
            ext_pan_id = [
              183
              37
              73
              23
              227
              96
              48
              16
            ];
            network_key = "!secret.yaml network_key";
            log_output = [ "console" ];
          };
          frontend = {
            enabled = true;
            host = "127.0.0.1";
            inherit (selfVars.services.zigbee2mqtt) port;
            url = "https://${vhost.domain}";
            auth_token = "!secret.yaml auth_token";
          };
        };
      };

      systemd.services.zigbee2mqtt = {
        wants = [ "mosquitto.service" ];
        after = [ "mosquitto.service" ];
        environment.Z2M_ONBOARD_NO_SERVER = "1";
      };

      age.secrets."${z2mSecret}" = {
        file = secret z2mSecret;
        path = "${config.services.zigbee2mqtt.dataDir}/secret.yaml";
        owner = "zigbee2mqtt";
      };

      services.home-assistant.extraComponents = [ "mqtt" ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf (zigbeeCheck && tlsCheck) {
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
        locations."/" = {
          proxyPass = "http://${vhost.proxyEndpoint}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          # NOTE: the frontend holds its WebSocket open; devices may stay quiet
          # for longer than nginx's 60 s default
          extraConfig = ''
            proxy_read_timeout 1h;
            proxy_send_timeout 1h;
          '';
        };
      };
    })
    # |----------------------------------------------------------------------| #
  ];
}
