# --- modules/boot.nix
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

{ config, pkgs, lib, inputs, user, ... }:

with lib;
let
  cfg = config.tensormodules.boot;
in {
  options.tensormodules.boot = with types; {
    enable = mkBoolOpt false;

    systemd = mkOption {
      type = bool;
      default = true;
      description = "";
    };

    grub = mkOption {
      type = bool;
      default = false;
      description = "";
    };

    multiboot = mkOption {
      type = bool;
      default = false;
      description = "";
    };

    configurationLimit = mkOption {
      type = int;
      default = 3;
      description = "";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.systemd || !cfg.grub) &&
                    (cfg.systemd || cfg.grub);
        message = "(Exactly) one bootloader needs to be provided";
      }
    ];

    boot.loader.systemd.enable = cfg.systemd;

    boot.loader.systemd-boot = mkIf cfg.systemd {
      enable = true;
      configurationLimit = cfg.configurationLimit;
    };

    boot.loader.grub = mkIf cfg.grub {
      enable = true;
      configurationLimit = cfg.configurationLimit;
      version = 2;

      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.timeout = 1;
  };
}

  # boot.loader.efi = {
  #   canTouchEfiVariables = true;
  #   efiSysMountPoint = "/boot";
  # };
  # boot.loader.grub = {
  #   enable = true;
  #   version = 2;
  #   devices = [ "nodev" ];
  #   efiSupport = true;
  #   useOSProber = true;
  #   configurationLimit = 2;
  # };