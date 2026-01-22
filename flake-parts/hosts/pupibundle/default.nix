# --- flake-parts/hosts/pupibundle/default.nix
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
{ inputs, infraVars }:
{
  config,
  pkgs,
  nixos-raspberrypi,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
  prometheusExporters = selfVars.services.prometheus.exporters;

  virtualHostsVar = infraVars.hosts."remotebundle".services.nginx.virtualHosts;
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Rpi5 with Argon One V3 case

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    # (inputs.nix-mineral + "/nix-mineral.nix")
    # ./nm-overrides.nix
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./disko.nix
  ]
  ++ (with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    raspberry-pi-5.display-vc4
    raspberry-pi-5.bluetooth
  ]);

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ pkgs.raspberrypi-eeprom ];

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------

  tensorfiles = {
    profiles = {
      headless.enable = true;
      packages-base.enable = true;
      # packages-extra.enable = true;

      with-base-monitoring-exports.enable = true;
    };

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;

    tasks.nix-garbage-collect.enable = false;
    programs.nh.enable = true;

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

  security.sudo.extraRules = [
    {
      users = [ "tsandrini" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  tensorfiles.networking.firewall.subnets-firewall = {
    enable = true;
    subnets = {
      "${infraVars.common.networking.defaultSubnet}" = {
        allowedTCPPorts = [
          80
          443
          prometheusExporters.pihole.port
          prometheusExporters.unbound.port
        ];
      };
      "${infraVars.common.networking.intranetSubnet}" = {
        allowedTCPPorts = [
          80
          443
          prometheusExporters.pihole.port
          prometheusExporters.unbound.port
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
    ];
    allowedUDPPorts = [
    ];
  };

  networking = {
    interfaces.end0.ipv4.addresses = [
      {
        inherit (selfVars) address;
        prefixLength = 24;
      }
    ];
    inherit (infraVars.common.networking) defaultGateway;
    nameservers = [ "127.0.0.1" ];
  };

  # free up :53 (Pi-hole needs it; systemd-resolved otherwise grabs 127.0.0.53:53)
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  services.dnsmasq.enable = false;

  services.unbound = {
    enable = true;
    localControlSocketPath = "/run/unbound/unbound.ctl";

    settings = {
      server = {
        local-zone = [
          ''"home.tsandrini.sh." static''
        ];

        local-data = [
          ''"pihole.home.tsandrini.sh. A ${infraVars.hosts."remotebundle".wgAddress}"''
        ];

        interface = [ "127.0.0.1" ];
        inherit (selfVars.services.unbound) port;
        access-control = [ "127.0.0.1 allow" ];

        # security hardening defaults
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;
        hide-identity = true;
        hide-version = true;

        # Logging
        verbosity = 3;
        log-queries = true;
        log-replies = true;
        log-local-actions = true;

        # Keep RFC1918 / link-local from being leaked upstream
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
        ];

        # Root hints + trust anchor (for fully recursive operation)
        root-hints = "${pkgs.dns-root-data}/root.hints";
        auto-trust-anchor-file = "/var/lib/unbound/root.key"; # DNSSEC
      };
    };
  };

  services.pihole-ftl = {
    enable = true;

    openFirewallDNS = true;
    openFirewallWebserver = true;

    lists = [
      {
        enabled = true;
        url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
        type = "block";
        description = "Big broom - Cleans the Internet and protects your privacy! Blocks Ads, Affiliate, Tracking, Metrics, Telemetry, Phishing, Malware, Scam, Fake, Cryptojacking and other Crap.";
      }
      {
        enabled = true;
        url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt";
        type = "block";
        description = "A blocklist for blocking Malware, Cryptojacking, Scam, Spam and Phishing. Blocks domains known to spread malware, launch phishing attacks and host command-and-control servers.";
      }
      {
        enabled = true;
        url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt";
        type = "block";
        description = "A blocklist for blocking fake stores, -streaming, rip-offs, cost traps and co.";
      }
      {
        enabled = true;
        url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt";
        type = "block";
        description = "A blocklist for annoying and malicious pop-up ads.";
      }
    ];

    settings = {
      dns = {
        interface = "end0";
        listeningMode = "SINGLE";
        upstreams = [ "127.0.0.1#${toString config.services.unbound.settings.server.port}" ];

        domainNeeded = true;
        expandHosts = true;

        # hosts = [ "10.10.0.1 mikrobundle" "10.10.0.10 pupibundle" ];
      };

      webserver = {
        port = "80";
        serve_all = true;
        interface.theme = "default-darker";
      };

      # webserver.api.pwhash = "…";
    };
  };

  services.pihole-web = {
    enable = true;
    hostName = virtualHostsVar."intra-pihole".domain;
    ports = [ "80" ];
  };

  # WARNING API: Failed to read /etc/pihole/versions (key: internal_error)
  systemd.tmpfiles.rules = [
    "f /etc/pihole/versions 0644 pihole pihole - -"
  ];

  # services.home-assistant = {
  #   enable = true;
  #   extraComponents = [
  #     # Components required to complete the onboarding
  #     "analytics"
  #     "google_translate"
  #     "met"
  #     "radio_browser"
  #     "shopping_list"
  #     # Recommended for fast zlib compression
  #     # https://www.home-assistant.io/integrations/isal
  #     "isal"
  #   ];
  #   config = {
  #     # Includes dependencies for a basic setup
  #     # https://www.home-assistant.io/integrations/default_config/
  #     default_config = { };
  #   };
  # };

  services.prometheus.exporters = {
    pihole = {
      enable = true;
      inherit (prometheusExporters.pihole) port;
      piholeHostname = "localhost";
    };
    unbound = {
      enable = true;
      inherit (config.services.unbound) group;
      inherit (prometheusExporters.unbound) port;
      unbound.host = "unix://${config.services.unbound.localControlSocketPath}";
      # unbound.host = "tcp://localhost:${toString config.services.unbound.settings.server.port}";
    };
  };
}
