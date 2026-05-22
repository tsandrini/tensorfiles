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
  importApply,
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
  imports = [
    (inputs.vpsadminos + "/os/lib/nixos-container/unstable/vpsadminos.nix")

    (importApply ./parts/nginx-proxy.nix { inherit inputs secretsPath infraVars; })
    (importApply ./parts/postgres.nix { inherit secretsPath infraVars; })
    (importApply ./parts/forgejo.nix { inherit infraVars; })
    (importApply ./parts/immich.nix { inherit infraVars; })
    (importApply ./parts/monitoring.nix { inherit secretsPath infraVars; })
    (importApply ./parts/mailserver.nix { inherit infraVars inputs secretsPath; })
    (importApply ./parts/mrpack-host.nix { inherit infraVars; })
    # (importApply ./parts/firefly.nix { inherit secretsPath infraVars; })
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [ ];

  tensorfiles = {
    profiles = {
      headless.enable = true;
      with-base-monitoring-exports.enable = true;
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
    options = [ "nofail" ];
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
            "10.20.0.0/24"
            "10.0.0.0/24"
            "10.5.0.0/24"
          ];

          endpoint = "vpn.tsandrini.sh:51821";
          persistentKeepalive = 25;
        }
      ];
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
