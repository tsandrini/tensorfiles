# --- flake-parts/hosts/krupikbundle/hardware-configuration.nix
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
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;

  # Killer E3000 2.5GbE (Realtek, r8169): magic packet only -- link-change /
  # broadcast wake (`p u b m`) powers a box back on right after shutdown
  networking.interfaces.enp131s0.wakeOnLan = {
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
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
        # NOTE: required for the initrd sshd (remote LUKS unlock, see default.nix)
        "r8169"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    # NOTE: VT-d DMA remapping behind the Thunderbolt 4 ports (boltd's
    # iommu_dma_protection); the firmware has VT-d on, this keeps the kernel side on
    kernelParams = [ "intel_iommu=on" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    # Arrow Lake iGPU (xe): VA-API for video decode; the dGPU does the rendering
    graphics.extraPackages = [ pkgs.intel-media-driver ];
    # RTX 5070 mobile (GB206, Blackwell) owns the display outputs and is the
    # boot VGA; this GPU generation runs on the open kernel module only
    nvidia = {
      open = true;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      powerManagement.enable = false;
      nvidiaSettings = false;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # 8 GiB swapfile on the LUKS-backed root (no hibernation: the box never sleeps)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];
}
