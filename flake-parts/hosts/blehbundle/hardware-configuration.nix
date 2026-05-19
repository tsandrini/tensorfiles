# --- flake-parts/hosts/blehbundle/hardware-configuration.nix
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
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];

    # NOTE: tty0 for SCP VNC ("Screen"), ttyS0 as a fallback log sink
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];

    loader = {
      timeout = 1;
      grub.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        # NOTE: mirror kernelParams onto the boot menu serial
        consoleMode = "auto";
      };
    };

    tmp.cleanOnBoot = true;
  };

  services.qemuGuest.enable = true;

  # NOTE: SSD-backed; lets disko's discard hints actually free blocks
  services.fstrim.enable = true;

  # NOTE: in lieu of a swap partition (Option A); zstd over the existing 8 GB RAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # IPv4 via DHCP on the public iface (Netcup hands it out automatically).
  # IPv6: Netcup routes 2a03:4000:19:24e::/64 to this VM but does NOT do
  # SLAAC/DHCPv6 — both the address and the link-local default gateway must
  # be configured statically.
  networking = {
    useDHCP = lib.mkDefault true;

    interfaces.ens3.ipv6.addresses = [
      {
        address = "2a03:4000:19:24e::1";
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
