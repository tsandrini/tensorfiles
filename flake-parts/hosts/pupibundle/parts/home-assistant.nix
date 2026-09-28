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
{ infraVars }:
{
  config,
  lib,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
  homeAssistantVars = selfVars.services.home-assistant;

  # UI-editable files that configuration.yaml `!include`s; HA does not create them
  uiIncludes = {
    automation = "automations.yaml";
    scene = "scenes.yaml";
    script = "scripts.yaml";
  };
in
{
  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        homeAssistantVars.port
      ];
    };
  };

  services.home-assistant = {
    enable = true;

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
    ];

    config = {
      # NOTE: any core key in YAML (the module injects time_zone) locks the whole
      # core config in the UI; the wizard owns it, keeping coordinates out of git
      homeassistant.time_zone = null;

      default_config = { };
      http.server_port = homeAssistantVars.port;
    }
    // lib.mapAttrs' (domain: file: lib.nameValuePair "${domain} ui" "!include ${file}") uiIncludes;
  };

  systemd.tmpfiles.rules = lib.mapAttrsToList (
    _: file: "f ${config.services.home-assistant.configDir}/${file} 0644 hass hass - -"
  ) uiIncludes;
}
