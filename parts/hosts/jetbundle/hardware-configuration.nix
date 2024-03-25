# --- parts/hosts/jetbundle/hardware-configuration.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
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
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  environment.systemPackages = with pkgs; [ libva-utils ];

  networking.useDHCP = lib.mkDefault true;

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    blacklistedKernelModules = [ ];
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  programs.gamemode.enable = true;
  services.fwupd.enable = true;

  services.open-fprintd.enable = true;
  services.python-validity.enable = true;

  # Thinkpad x270 fingreprint reader
  # Unfortunately the official services.fprintd option doesn't work and any
  # custom tos drivers didn't work either. The only way to make it work was to
  # use open-fprintd and python-validity services.
  systemd.units."open-fprintd-suspend".enable = true;
  systemd.units."open-fprintd-resume".enable = true;

  security.pam.services = {
    sudo.fprintAuth = true;
    # NOTE doesn't work unfortunately
    # login.fprintAuth = true;
    # sddm.fprintAuth = true;
    # xscreensaver.fprintAuth = true;
    # kwallet.fprintAuth = true;
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
        configurationLimit = 3;
      };
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    opentabletdriver.enable = true;

    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        #intel-media-driver
        #vaapiIntel
        #vaapiVdpau
        #libvdpau-va-gl
      ];
    };

    bluetooth = {
      enable = true;
    };
  };
  # Hardware hybrid decoding
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
}
