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
{ inputs }:
{
  config,
  pkgs,
  nixos-raspberrypi,
  ...
}:
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
      with-base-monitoring-exports.prometheus.exporters.node.openFirewall = true;
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

  # networking.firewall = {
  #   allowedTCPPorts = [
  #     80
  #     443
  #   ];
  #   allowedUDPPorts = [
  #   ];
  # };

  networking = {
    interfaces.end0.ipv4.addresses = [
      {
        address = "10.10.0.10";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.10.0.1";
    nameservers = [ "127.0.0.1" ];
  };

  # nix-mineral.enable = true;

  # free up :53 (Pi-hole needs it; systemd-resolved otherwise grabs 127.0.0.53:53)
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  services.dnsmasq.enable = false;

  services.unbound = {
    enable = true;

    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        port = 5335;
        access-control = [ "127.0.0.1 allow" ];

        # security hardening defaults
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;
        hide-identity = true;
        hide-version = true;

        # Keep RFC1918 / link-local from being leaked upstream
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
        ];

        # Root hints + trust anchor (for fully recursive operation)
        root-hints = "${pkgs.dns-root-data}/root.hints";
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
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
        port = "80r,443s";
        serve_all = true;
        interface.theme = "default-darker";
      };

      # webserver.api.pwhash = "…";
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [
      "80r"
      "443s"
    ];
    # hostName = "10.10.0.10";
  };
}
