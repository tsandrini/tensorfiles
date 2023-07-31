# --- modules/profiles/base.nix
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
{ config, lib, pkgs, inputs, ... }:
with builtins;
with lib;
let
  cfg = config.tensorfiles.profiles.base;
  # Note: module level = 500
  #       profile level = 400
  _ = mkOverride 400;
in {
  # TODO find a better place for the stateVersion expression
  options.tensorfiles.profiles.base = with types; {
    enable = mkEnableOption (mdDoc ''
      Base profile, WIP, will probably be decoupled in the future
    '');

    modulesAutoenable = {
      enable = mkEnableOption (mdDoc ''
        Autoenabling of the imported modules
      '') // {
        default = true;
      };

      hardware = mkEnableOption
        (mdDoc "Autoenabling all of the modules/hardware/ NixOS modules") // {
          default = true;
        };
      misc = mkEnableOption
        (mdDoc "Autoenabling all of the modules/misc/ NixOS modules") // {
          default = true;
        };
      programs = mkEnableOption
        (mdDoc "Autoenabling all of the modules/programs/ NixOS modules") // {
          default = true;
        };
      security = mkEnableOption
        (mdDoc "Autoenabling all of the modules/security/ NixOS modules") // {
          default = true;
        };
      services = mkEnableOption
        (mdDoc "Autoenabling all of the modules/services/ NixOS modules") // {
          default = true;
        };
      system = mkEnableOption
        (mdDoc "Autoenabling all of the modules/system/ NixOS modules") // {
          default = true;
        };
      tasks = mkEnableOption
        (mdDoc "Autoenabling all of the modules/tasks/ NixOS modules") // {
          default = true;
        };

      homeSettings = mkEnableOption (mdDoc ''
        Autoenables all of the multi-user home-manager home.settings
        configuration. This basically just sets `home.enable = true;` for all
        of the modules that support it.
      '') // {
        default = true;
      };
    };
  };

  # TODO import
  # cleanup
  imports = with inputs.self.nixosModules; [
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.nur.nixosModules.nur

    misc.nix
    misc.xdg

    programs.git
    programs.shells.zsh

    security.agenix

    services.networking.networkmanager
    services.x11.window-managers.xmonad

    system.persistence
    # system.users

    tasks.system-autoupgrade
    tasks.nix-garbage-collect
  ];

  config = mkIf cfg.enable (mkMerge [
    ({ system.stateVersion = _ "23.05"; })
    (mkIf cfg.modulesAutoenable.enable {
      # tensorfiles.hardware = mkIf cfg.modulesAutoenable.hardware {
      #   #
      # };
      tensorfiles.misc = mkIf cfg.modulesAutoenable.misc {
        nix.enable = _ true;
        xdg.enable = _ true;
      };
      tensorfiles.programs = mkIf cfg.modulesAutoenable.programs {
        git.enable = _ true;
        shells.zsh.enable = _ true;
      };
      tensorfiles.security = mkIf cfg.modulesAutoenable.security {
        #
        agenix.enable = _ true;
      };
      tensorfiles.services = mkIf cfg.modulesAutoenable.services {
        networking.networkmanager.enable = _ true;
        x11.window-managers.xmonad.enable = _ true;
      };
      tensorfiles.system = mkIf cfg.modulesAutoenable.system {
        # users.enable = _ true;
        persistence.enable = _ true;
      };
      tensorfiles.tasks = mkIf cfg.modulesAutoenable.tasks {
        nix-garbage-collect.enable = _ true;
        system-autoupgrade.enable = _ true;
      };
    })
    (mkIf (cfg.modulesAutoenable.enable && cfg.modulesAutoenable.homeSettings) {
      tensorfiles.programs.shells.zsh.home.enable = _ true;
      tensorfiles.programs.git.home.enable = _ true;
      tensorfiles.misc.xdg.home.enable = _ true;
    })
    ({
      # TODO move this
      tensorfiles.system.persistence.btrfsWipe = {
        enable = _ true;
        rootPartition = _ "/dev/mapper/enc";
      };

      time.timeZone = _ "Europe/Prague";
      i18n.defaultLocale = _ "en_US.UTF-8";

      console = {
        enable = _ true;
        useXkbConfig = _ true;
        font = _ "ter-132n";
      };

      environment.systemPackages = with pkgs; [
        # BASE UTILS
        git
        htop
        wget
        curl
        jq
        killall
        openssl
        vim
        # HW
        exfat
        dosfstools
        exfatprogs
        udisks
        pciutils
        usbutils
      ];
    })
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
