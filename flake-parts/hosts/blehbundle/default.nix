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
  lib,
  pkgs,
  hostName,
  ...
}:
let
  selfVars = infraVars.hosts."${hostName}";

  # The official server pack zip from CurseForge ("Additional Files" section
  # on the modpack page). The author bundles the full mod set including
  # non-redistributable JARs. To bump pack version: replace this file and
  # bump the derivation name.
  aeronauticsServerpack =
    pkgs.runCommand "aoc-aeronautics-serverpack-v1.6"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p $out
        unzip -q ${./serverpack.zip} -d $out
      '';

  # Layer on top of the serverpack: filter mods we don't want, drop in mods
  # we do want. Currently:
  #  - continuity: client-only connected-textures mod, hard-depends on
  #    `connector` which Sinytra Connector beta.14 doesn't register on
  #    dedicated 1.21.1 servers (sinytra/Connector#1428). Server crashes
  #    on the dep check unless removed.
  #
  # NOTE: this used to symlink the jars via `cp -as ${src}/. $out/`. That
  # produces symlink targets with a `/./` segment in their path (e.g.
  # `/nix/store/...-serverpack/mods/./CrashAssistant-*.jar`). NeoForge's
  # JarInJar selector tries to load each mod's `META-INF/jarjar/*.jar` via
  # a `jij:` URI built from the outer jar path; with `/./` in there, mixin
  # config resources inside the embedded jar can't be opened and
  # `MixinInitialisationError: Error initialising mixin config
  # crash_assistant.mixins.json` fires during boot, with FML calling
  # System.exit(0). Copying the jars instead avoids the symlink path
  # entirely.
  aeronauticsServerMods =
    let
      excludedMods = [
        "continuity-*.jar"
      ];
      extraMods = [
        # future: pkgs.fetchurl { url = "https://cdn.modrinth.com/..."; hash = "..."; }
      ];
    in
    pkgs.runCommand "aeronautics-server-mods" { } ''
      mkdir -p $out
      cp -L ${aeronauticsServerpack}/mods/*.jar $out/
      chmod u+w -R $out
      ${lib.concatMapStringsSep "\n" (pat: "rm -f $out/${pat}") excludedMods}
      ${lib.concatMapStringsSep "\n" (m: "cp -L ${m} $out/") extraMods}
    '';

  # NOTE: temporarily commented out to verify that the mods=files= fix above
  # is the ONLY thing needed (i.e. that plain nix-minecraft + neoforgeServers
  # works once `mods/` is a real writable directory). Restore if the test fails.
  /*
    serverStarterJar = pkgs.fetchurl {
      url = "https://github.com/neoforged/ServerStarterJar/releases/download/0.1.34/server.jar";
      hash = "sha256-H2tc/eUQ69HeNfoVqLHjgooheIJ1CIEPtzfPc4eAhLI=";
    };

    neoforgePkg = pkgs.neoforgeServers.neoforge-1_21_1-21_1_228;

    aeronauticsServerPkg =
      pkgs.runCommand "aeronautics-neoforge-ssj"
        {
          meta.mainProgram = "minecraft-server";
        }
        ''
          mkdir -p $out/bin
          cat > $out/bin/minecraft-server <<EOF
          #!${pkgs.runtimeShell}
          exec ${pkgs.jdk21_headless}/bin/java "\$@" -jar ${serverStarterJar} nogui
          EOF
          chmod +x $out/bin/minecraft-server
        '';
  */
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
      # package = aeronauticsServerPkg;   # SSJ-wrapped variant (commented out for the simplification test)

      # Aikar-style G1GC flags tuned for Create-heavy packs. 5 GiB heap leaves
      # ~3 GiB for OS + JVM metaspace + Netty/native off-heap surges during
      # world-gen on the 8 GiB box. Dropped AlwaysPreTouch (was OOM-killing
      # the JVM during chunk-gen on first boot).
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
        difficulty = "normal";
        gamemode = "survival";
        max-players = 8;
        motd = "Henlo punťíííkuu, strčím ti prst do nosu :3 hi hi";
        white-list = true;
        online-mode = true;
        spawn-protection = 0;
        view-distance = 10;
        simulation-distance = 10;
      };

      symlinks = {
        # NOTE: SSJ-related symlinks (run.sh, user_jvm_args.txt, libraries,
        # server.jar) were commented out for the simplification test. Restore
        # together with `aeronauticsServerPkg` above if plain neoforgeServers
        # turns out to need them.
      };

      files = {
        "config" = "${aeronauticsServerpack}/config";
        "defaultconfigs" = "${aeronauticsServerpack}/defaultconfigs";

        # `mods/` MUST be a real directory of real files in the data dir.
        # When it's a symlink to /nix/store (the previous `symlinks=` approach),
        # `Path.toRealPath()` on each mod jar resolves to a /nix/store path,
        # and NeoForge's JarInJar selector fails to open mixin-config resources
        # inside JiJ-embedded jars (e.g. `crash_assistant.mixins.json` inside
        # `META-INF/jarjar/crash_assistant-neoforge.jar`) — likely because JiJ
        # needs a writable path for its in-process FS extraction. The failure
        # surfaces as `MixinInitialisationError` and FML calls `System.exit(0)`
        # without writing a crash report, matching the silent exit-0 we saw.
        # `files=` does `cp -r --dereference` into the data dir on every start
        # (~700 MB), which is slow but matches the proven /opt/aoc-manual layout.
        "mods" = aeronauticsServerMods;
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
