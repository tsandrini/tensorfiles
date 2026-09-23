# --- flake-parts/modules/nixos/misc/remote-builders.nix
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
  localFlake,
  infraVars,
  secretsPath,
  pubkeys,
}:
{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkForce
    mkEnableOption
    mkOption
    types
    attrValues
    concatMap
    concatStrings
    mapAttrs'
    mapAttrsToList
    nameValuePair
    optional
    subtractLists
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.misc.remote-builders;
  _ = mkOverrideAtModuleLevel;

  sshAlias = builderName: "nix-builder-${builderName}";
  builderSystems = concatMap (builder: builder.systems) (attrValues cfg.client.builders);

  builderSubmodule = {
    options = {
      systems = mkOption {
        type = types.listOf types.str;
        example = [ "aarch64-linux" ];
        description = ''
          Platforms the builder can build for, passed to
          `nix.buildMachines.*.systems`.
        '';
      };

      maxJobs = mkOption {
        type = types.ints.positive;
        default = 2;
        description = ''
          Maximum number of concurrent builds dispatched to the builder. Should
          match `tensorfiles.misc.remote-builders.server.maxJobs` on the
          builder host.
        '';
      };

      speedFactor = mkOption {
        type = types.ints.positive;
        default = 1;
        description = ''
          Relative speed of the builder; Nix prefers builders with a higher
          value when several of them support the same platform.
        '';
      };

      supportedFeatures = mkOption {
        type = types.listOf types.str;
        default = [
          "benchmark"
          "big-parallel"
          "nixos-test"
        ];
        description = ''
          System features the builder supports, passed to
          `nix.buildMachines.*.supportedFeatures`.
        '';
      };
    };
  };
in
{
  options.tensorfiles.misc.remote-builders = {
    server = {
      enable = mkEnableOption ''
        Enables NixOS module that configures the host as a Nix remote builder
        for other machines.

        Builds are run at idle CPU/IO priority and under a soft memory limit,
        so they yield to the services the host actually runs. Clients log in
        as the dedicated trusted `nix-ssh` user (`nix.sshServe`), which is
        locked to `nix-daemon --stdio` and has no shell.
      '';

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = pubkeys.common.nixRemoteBuilders;
        description = ''
          Public ssh keys of the clients allowed to use this builder.
        '';
      };

      maxJobs = mkOption {
        type = types.ints.positive;
        default = 2;
        description = ''
          Maximum number of concurrent build jobs (`nix.settings.max-jobs`).
        '';
      };

      cores = mkOption {
        type = types.ints.unsigned;
        default = 2;
        description = ''
          Number of cores a single build job may use (`nix.settings.cores`),
          `0` meaning all of them.
        '';
      };

      memoryHigh = mkOption {
        type = types.str;
        default = "5G";
        example = "75%";
        description = ''
          Soft memory limit (systemd `MemoryHigh=`) of the nix-daemon unit.
          Above it builds get throttled and pushed to swap instead of letting
          the OOM killer pick the host's services.
        '';
      };
    };

    client = {
      enable = mkEnableOption ''
        Enables NixOS module that offloads builds to remote builders over
        `ssh-ng`.

        Each builder is addressed through a dedicated ssh alias
        (`nix-builder-<name>`) with a pinned host key, and the private ssh key
        is provided as an agenix secret.
      '';

      builders = mkOption {
        type = types.attrsOf (types.submodule builderSubmodule);
        default = { };
        example = {
          pupibundle = {
            systems = [ "aarch64-linux" ];
            maxJobs = 2;
          };
        };
        description = ''
          Remote builders keyed by host name. Each name has to be present in
          `infraVars.hosts` (for its `address`) and have a `hostKey` in the
          agenix `pubkeys` (for host key pinning).
        '';
      };

      sshUser = mkOption {
        type = types.str;
        default = "nix-ssh";
        description = ''
          User to log in as on the builders. Has to be a trusted Nix user
          there; the default matches the user created by the server side.
        '';
      };

      sshKeySecretsPath = mkOption {
        type = types.str;
        default = "hosts/${hostName}/nix-remote-builder-ssh-key";
        description = ''
          Path (relative to the agenix secrets directory, without the `.age`
          suffix) of the private ssh key used to log in to the builders. The
          matching public key has to be in the builders'
          `server.authorizedKeys`.
        '';
      };

      disableLocalEmulation =
        mkEnableOption ''
          Removes the builders' platforms from the locally emulated ones
          (`boot.binfmt.emulatedSystems`) in `nix.settings.extra-platforms`,
          so builds for them always go to the builders instead of spilling over
          to slow local qemu-user emulation. The binfmt registrations are kept,
          so emulated binaries can still be run locally and a one-off emulated
          build can be forced with `--option extra-platforms <system>`.
        ''
        // {
          default = true;
        };
    };
  };

  config = mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.server.enable {
      assertions = [
        {
          assertion = cfg.server.authorizedKeys != [ ];
          message = "tensorfiles.misc.remote-builders.server: no client keys in `authorizedKeys`, nobody could use this builder.";
        }
      ];

      nix = {
        sshServe = {
          enable = _ true;
          protocol = _ "ssh-ng";
          write = _ true;
          trusted = _ true;
          keys = _ cfg.server.authorizedKeys;
        };
        settings = {
          max-jobs = _ cfg.server.maxJobs;
          cores = _ cfg.server.cores;
        };
        daemonCPUSchedPolicy = _ "idle";
        daemonIOSchedClass = _ "idle";
      };

      systemd.services.nix-daemon.serviceConfig.MemoryHigh = _ cfg.server.memoryHigh;
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.client.enable {
      nix = {
        distributedBuilds = _ true;
        buildMachines = mapAttrsToList (builderName: builder: {
          hostName = sshAlias builderName;
          protocol = "ssh-ng";
          inherit (cfg.client) sshUser;
          sshKey = config.age.secrets.${cfg.client.sshKeySecretsPath}.path;
          inherit (builder)
            systems
            maxJobs
            speedFactor
            supportedFeatures
            ;
        }) cfg.client.builders;
      };

      programs.ssh = {
        extraConfig = concatStrings (
          mapAttrsToList (builderName: _builder: ''
            Host ${sshAlias builderName}
              HostName ${infraVars.hosts.${builderName}.address}
              Port ${toString infraVars.common.services.openssh.defaultPort}
              HostKeyAlias ${sshAlias builderName}
              IdentitiesOnly yes
          '') cfg.client.builders
        );
        knownHosts = mapAttrs' (
          builderName: _builder:
          nameValuePair (sshAlias builderName) {
            publicKey = _ pubkeys.hosts.${builderName}.hostKey;
          }
        ) cfg.client.builders;
      };

      age.secrets.${cfg.client.sshKeySecretsPath} = {
        file = _ (secretsPath + "/${cfg.client.sshKeySecretsPath}.age");
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf
      (
        cfg.client.enable
        && cfg.client.disableLocalEmulation
        && config.boot.binfmt.addEmulatedSystemsToNixSandbox
        && config.boot.binfmt.emulatedSystems != [ ]
      )
      {
        # NOTE: mirrors the binfmt module's own definition minus the builders' systems
        nix.settings.extra-platforms = mkForce (
          subtractLists builderSystems (
            config.boot.binfmt.emulatedSystems ++ optional pkgs.stdenv.hostPlatform.isx86_64 "i686-linux"
          )
        );
      }
    )
    # |----------------------------------------------------------------------| #
  ];

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
