# --- flake-parts/modules/nixos/system/impermanence.nix
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
{ localFlake, inputs }:
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    hasAttr
    mkBefore
    mkEnableOption
    mkOption
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkAgenixEnableOption;

  cfg = config.tensorfiles.system.impermanence;
  _ = mkOverrideAtModuleLevel;

  agenixCheck = (isModuleLoadedAndEnabled config "tensorfiles.security.agenix") && cfg.agenix.enable;
in
{
  options.tensorfiles.system.impermanence = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the persistence ecosystem.
      Doing so enables other modules to automatically use the persistence instead
      of manually having to set it up yourself.
    '';

    agenix = {
      enable = mkAgenixEnableOption;
    };

    disableSudoLectures = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to disable the default sudo lectures that would be
        otherwise printed every time on login
      '';
    };

    persistentRoot = mkOption {
      type = types.path;
      default = "/persist";
      description = ''
        Path on the already mounted filesystem for the persistent root, that is,
        a root where we should store the persistent files and against which should
        we link the temporary files against.

        This is usually simply just /persist.
      '';
    };

    allowOther = mkOption {
      type = types.bool;
      default = false;
      description = ''
        TODO
      '';
    };

    btrfsWipe = {
      enable = mkEnableOption ''
        Enable btrfs based root filesystem wiping.

        This has the following requirements
        1. The user needs to have a btrfs formatted root partition (`rootPartition`)
           with a root subvolume `rootSubvolume`. This means that the whole
           system is going to reside on one partition.

           Additional decoupling can be achieved then by btrfs subvolumes.
        2. The user needs to create a blank snapshot of `rootSubvolume` during
           installation specified by `blankRootSnapshot`.

        The TL;DR of this approach is that we basically just restore the rootSubvolume
        to its initial blank snaphost.

        You can populate the root partition with any amount of desired btrfs
        subvolumes. The `rootSubvolume` is the only one required.
      '';

      rootPartition = mkOption {
        type = types.path;
        default = "/dev/sda1";
        description = ''
          The dev path for the main btrfs formatted root partition that is
          mentioned in the btrfsWipe.enable doc.
        '';
      };

      rootSubvolume = mkOption {
        type = types.str;
        default = "root";
        description = ''
          The main root btrfs subvolume path that is going to be reset to
          blankRootSnapshot later.
        '';
      };

      blankRootSnapshot = mkOption {
        type = types.str;
        default = "root-blank";
        description = ''
          The btrfs snapshot of the main rootSubvolume. You will probably
          need to create this one manually during the installation & formatting
          of the system. One such way is using the following command:

          btrfs su snapshot -r /mnt/root /mnt/root-blank
        '';
      };

      mountpoint = mkOption {
        type = types.path;
        default = "/mnt";
        description = ''
          Temporary mountpoint that should be used for mounting and resetting
          the rootPartition.

          This is useful mainly if you want to prevent some conflicts.
        '';
      };
    };
  };

  imports = [ inputs.impermanence.nixosModules.impermanence ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      assertions = [
        {
          assertion = hasAttr "impermanence" inputs;
          message = "Impermanence flake missing in the inputs library. Please add it to your flake inputs.";
        }
      ];
    }
    # |----------------------------------------------------------------------| #
    {
      environment.persistence = {
        "${cfg.persistentRoot}" = {
          hideMounts = _ true;
          directories = [
            "/etc/tensorfiles" # TODO probably not needed anymore ? not sure
            "/var/lib/bluetooth" # TODO move bluetooth to hardware
            "/var/lib/systemd/coredump"
          ];
          files = [
            "/etc/adjtime"
            "/etc/machine-id"
          ];
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.disableSudoLectures {
      security.sudo.extraConfig = mkBefore ''
        # rollback results in sudo lectures after each reboot
        Defaults lecture = never
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.btrfsWipe.enable {
      boot.initrd.postDeviceCommands =
        with cfg.btrfsWipe;
        mkBefore ''
          mkdir -p ${mountpoint}

          # We first mount the btrfs root to ${mountpoint}
          # so we can manipulate btrfs subvolumes.
          mount -o subvol=/ ${rootPartition} ${mountpoint}

          # While we're tempted to just delete /${rootPartition} and create
          # a new snapshot from /${blankRootSnapshot}, /${rootPartition} is already
          # populated at this point with a number of subvolumes,
          # which makes `btrfs subvolume delete` fail.
          # So, we remove them first.
          #
          # /root contains subvolumes:
          # - /root/var/lib/portables
          # - /root/var/lib/machines
          #
          # I suspect these are related to systemd-nspawn, but
          # since I don't use it I'm not 100% sure.
          # Anyhow, deleting these subvolumes hasn't resulted
          # in any issues so far, except for fairly
          # benign-looking errors from systemd-tmpfiles.
          btrfs subvolume list -o ${mountpoint}/${rootSubvolume} |
          cut -f9 -d' ' |
          while read subvolume; do
            echo "deleting /$subvolume subvolume..."
            btrfs subvolume delete "${mountpoint}/$subvolume"
          done &&
          echo "deleting /${rootSubvolume} subvolume..." &&
          btrfs subvolume delete ${mountpoint}/${rootSubvolume}

          echo "restoring blank /${rootSubvolume} subvolume..."
          btrfs subvolume snapshot ${mountpoint}/${blankRootSnapshot} ${mountpoint}/${rootSubvolume}

          # Once we're done rolling back to a blank snapshot,
          # we can unmount ${mountpoint} and continue on the boot process.
          umount ${mountpoint}
        '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.allowOther { programs.fuse.userAllowOther = true; })
    # |----------------------------------------------------------------------| #
    (mkIf agenixCheck {
      age.identityPaths = [ "${cfg.persistentRoot}/etc/ssh/ssh_host_ed25519_key" ];

      environment.persistence = {
        "${cfg.persistentRoot}" = {
          files = [
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
          ];
        };
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
