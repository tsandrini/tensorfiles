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
  infraVars,
  secretsPath,
}:
{
  config,
  pkgs,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  aeronauticsModpack = pkgs.fetchPackwizModpack {
    src = inputs.packwiz-lt-aoc-aeronautics;
    packHash = "sha256-p0NbOcvCsMmFGwkpggrEI73vZ4/ynrtX778lcLsXNsg=";
    # packHash = lib.fakeHash;
    side = "server";
  };

in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Netcup VPS 1000 G11s (KVM/QEMU, 4 vCPU, 8 GB RAM, 256 GB virtio-blk)

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nix-mineral.nixosModules.nix-mineral
    inputs.nix-minecraft.nixosModules.minecraft-servers

    ./hardware-configuration.nix
    ./disko.nix
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
      agenixPassword.enable = false;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = false;
      extraGroups = [ "input" ];
    };
  };

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        25565
      ];
      allowedUDPPorts = [
        config.networking.wireguard.interfaces.wg-home-tunnel.listenPort
        25565
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        #
      ];
    };
  };

  nix-mineral = {
    # TODO: temporarily turned off to eliminate any potential issues,
    # after the server will be functional, we can enable it back again
    enable = false;
    preset = "performance";
    settings = {
      network.ip-forwarding = true;
    };
    extras.system.minimize-swapping = true;
    # NOTE: Sinytra Connector / JNA / oshi-core need to extract and exec
    # native libraries from `java.io.tmpdir` (= /tmp by default). nix-mineral's
    # default hardening sets /tmp to noexec; turn it off so the modded server
    # can load native code. nosuid/nodev are still applied.
    filesystems.normal."/tmp".options."noexec" = false;
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

          # endpoint = "vpn.tsandrini.sh:51821";
          endpoint = "[2a02:8308:298:c900::a]:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;

    servers.lt-aoc-aeronautics = {
      enable = true;
      autoStart = true;

      # NeoForge 21.1.228 — matches variables.txt MODLOADER_VERSION in the
      # serverpack.
      package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_228;

      # Aikar-style G1GC flags tuned for Create-heavy packs.
      jvmOpts = builtins.concatStringsSep " " [
        "-Xms6G"
        "-Xmx6G"
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
        "-XX:G1ReservePercent=20"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
        "-Dlog4j2.formatMsgNoLookups=true"
      ];

      whitelist = {
        "tsandrini" = "73cdb8a9-a7fc-49be-89d9-ad3924b71b44";
        "A_Tarkus" = "f8bde3b3-839b-45f7-91ef-3e070d22041a";
        "TenMarky" = "53e7d569-b7be-4595-95ea-e6fb9123efa9";
        "zenmaya" = "e32e9504-8b66-48b5-a1ac-a8484894ceaf";
        "Sarianille" = "f8686022-6a6e-4e61-bf86-d5891676a599";
      };

      serverProperties = {
        server-port = 25565;
        level-name = "lt-aoc-aeronautics2";
        difficulty = "normal";
        gamemode = "survival";
        max-players = 8;
        motd = "Henlo punťíííkuu, strčím ti prst do nosu :3 hi hi";
        white-list = true;
        online-mode = true;
        spawn-protection = 16;
        view-distance = 10;
        simulation-distance = 10;
      };

      files = {
        # fetchPackwizModpack keeps overrides at ${modpack}/overrides/<name>
        # rather than merging them into the pack root.
        "config" = "${aeronauticsModpack}/overrides/config";
        "defaultconfigs" = "${aeronauticsModpack}/overrides/defaultconfigs";

        # `mods` MUST go through `files=` (real dir copy), not `symlinks=`.
        # NeoForge JarInJar resolves each jar via `Path.toRealPath()`; if that
        # lands in /nix/store, mixin configs inside JiJ-embedded jars can't be
        # opened and FML aborts with `MixinInitialisationError` + System.exit(0).
        # `files=` does `cp -r --dereference` (~700 MB) on every start.
        "mods" = "${aeronauticsModpack}/mods";
      };

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
