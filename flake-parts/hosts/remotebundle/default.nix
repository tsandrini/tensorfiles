# --- flake-parts/hosts/remotebundle/default.nix
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
{
  inputs,
  secretsPath,
  infraVars,
}:
{
  config,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # VPSfree container

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  # NOTE: FROZEN since the 2026-10-18 cutover to blehbundle
  # (meta/plans/vps-migration.md). The service parts stay unimported so a
  # vpsFree node reboot brings up only ssh/WireGuard; all state is left on
  # disk as the fallback until vpsFree is cancelled.
  imports = [
    (inputs.vpsadminos + "/os/lib/nixos-container/unstable/vpsadminos.nix")
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ ];

  tensorfiles = {
    profiles = {
      headless.enable = true;
      with-base-monitoring-exports.enable = true;
      with-deploy-user.enable = true;
    };

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;

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

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
      allowedUDPPorts = [
        config.networking.wireguard.interfaces.wg-home-tunnel.listenPort
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        #
      ];
    };
  };

  # NAS
  fileSystems."/mnt/NAS" = {
    device = "172.16.131.12:/nas/5829";
    fsType = "nfs";
    # NOTE: the NFS client takes a random privileged source port (665-1023)
    # and once grabbed dovecot's 993; mount after dovecot so it can't.
    # `noresvport` is no option, the NAS rejects unprivileged ports.
    options = [
      "nofail"
      "x-systemd.after=dovecot.service"
    ];
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

  networking.wireguard.interfaces = {
    wg-home-tunnel = {
      ips = [ "${selfVars.wgAddress}/32" ];
      listenPort = 51821;
      privateKeyFile = config.age.secrets."hosts/${hostName}/wg-home-tunnel-privkey".path;

      peers = [
        {
          publicKey = "RY2XHIRk+2RtA27EUQdLj+CcqAP2Izj4cGI3Nm0d5CE="; # pragma: allowlist secret

          allowedIPs = [
            infraVars.common.networking.defaultSubnet
            infraVars.common.networking.intranetSubnet
            "10.0.0.0/24"
            "10.5.0.0/24"
          ];

          # NOTE: endpoint is owned by wireguard-endpoint-watchdog below, not set
          # here -- `wg set` latches the first getaddrinfo result forever, and
          # vpn.tsandrini.sh has an AAAA the router does not answer WireGuard on.
          persistentKeepalive = 25;
        }
      ];
    };
  };

  tensorfiles.networking.wireguard-endpoint-watchdog = {
    enable = true;
    interfaces.wg-home-tunnel = {
      peerPublicKey = "RY2XHIRk+2RtA27EUQdLj+CcqAP2Izj4cGI3Nm0d5CE="; # pragma: allowlist secret
      endpointHost = "vpn.tsandrini.sh";
      endpointPort = 51821;
      addressFamily = "ipv4";
    };
  };

  services.prometheus.exporters = {
    #
  };

  age.secrets = {
    "hosts/${hostName}/wg-home-tunnel-privkey" = {
      file = "${secretsPath}/hosts/${hostName}/wg-home-tunnel-privkey.age";
    };
  };
}
