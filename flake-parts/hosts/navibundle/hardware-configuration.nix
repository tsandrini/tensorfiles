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
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  # manual escape hatches for the Wi-Fi driver; see the ath12k NOTE below
  wifi-on = pkgs.writeShellApplication {
    name = "wifi-on";
    runtimeInputs = [
      pkgs.kmod
      pkgs.networkmanager
      pkgs.pciutils
    ];
    text = ''
      # NOTE: after an ath12k crash + warm reset the module drops off the PCIe
      # bus (bridge 0d:06.0, bus 10 empty) until a real cold power cycle
      if [ -z "$(lspci -d 17cb:)" ]; then
        echo "wifi-on: no Qualcomm WCN785x on the PCI bus -- cold power cycle (PSU off ~30 s) needed" >&2
        exit 1
      fi
      sudo modprobe ath12k_wifi7
      for _ in $(seq 20); do nmcli -t -f DEVICE,TYPE device | grep -q ':wifi$' && break; sleep 0.5; done
      nmcli radio wifi on
      nmcli -f DEVICE,TYPE,STATE device | grep -E 'DEVICE|wifi'
    '';
  };
  wifi-off = pkgs.writeShellApplication {
    name = "wifi-off";
    runtimeInputs = [
      pkgs.kmod
      pkgs.networkmanager
    ];
    text = ''
      nmcli radio wifi off
      sudo modprobe -r ath12k_wifi7 ath12k
    '';
  };
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;

  # Realtek RTL8126 5GbE: magic packet only -- link-change/broadcast wake
  # (`p u b m`) makes the box power itself back on after shutdown
  networking.interfaces.enp17s0.wakeOnLan = {
    enable = true;
    policy = [ "magic" ];
  };

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

  # NOTE: the WCN7850 Wi-Fi 7 driver (ath12k) can die re-initialising inside
  # the resume path (order-8 GFP_NOIO alloc, no reclaim allowed) and a
  # half-initialised radio oopses on unload -> reboot. So the driver never
  # crosses a sleep: unloaded before suspend, reloaded after resume in normal
  # context. A wedged module also drops off the PCIe bus and keeps asserting
  # WAKE# (box powers itself back on) until a real cold power cycle.
  powerManagement = {
    powerDownCommands = ''
      if grep -q '^ath12k_wifi7 ' /proc/modules; then
        touch /run/ath12k-reload
        ${pkgs.kmod}/bin/modprobe -r ath12k_wifi7 ath12k
      fi
    '';
    resumeCommands = ''
      if [ -e /run/ath12k-reload ]; then
        rm -f /run/ath12k-reload
        ${pkgs.kmod}/bin/modprobe ath12k_wifi7
      fi
    '';
  };
  environment.systemPackages = [
    wifi-on
    wifi-off
  ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    # opentabletdriver.enable = true;
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
