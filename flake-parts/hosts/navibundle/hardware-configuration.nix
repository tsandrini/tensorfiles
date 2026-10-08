# --- flake-parts/hosts/navibundle/hardware-configuration.nix
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
# Generated with `nixos-generate-config --show-hardware-config --no-filesystems`
# on the navibundle-installer live system (2026-10-06); filesystems come from
# ./disko.nix, the HDD mount is declared below.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;

  boot = {
    loader = {
      timeout = 1;
      grub.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
    };
    # ARM cross builds / emulation (same as flatbundle)
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci_prom21"
        "ahci"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      # early KMS for the RX 9070 XT (smooth console + plymouth hand-over)
      kernelModules = [ "amdgpu" ];
    };
    kernelModules = [
      "kvm-amd"
      # Gigabyte ITE IT8689E Super I/O: board fan / voltage / thermistor sensors
      "it87"
    ];
    extraModulePackages = [ config.boot.kernelPackages.it87 ];
    extraModprobeConfig = ''
      options it87 ignore_resource_conflict=1
    '';
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
  };

  # 16 GiB swapfile on the LUKS-backed root (no hibernation)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Seagate ST1500DM003 1.5 TB, manual backups / scratch (ext4 label from its
  # previous life as flatbundle's enclosure disk)
  fileSystems."/mnt/hdd-backup" = {
    device = "/dev/disk/by-label/hdd-backup";
    fsType = "ext4";
    options = [
      "nofail"
      "nosuid"
      "nodev"
      "noatime"
      "x-systemd.device-timeout=10s"
    ];
  };
}
