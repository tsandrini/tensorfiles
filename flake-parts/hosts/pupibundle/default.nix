# --- flake-parts/hosts/pupibundle/default.nix
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
{ inputs }:
{
  pkgs,
  system,
  nixos-raspberrypi,
  ...
}:
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Rpi5 with Argon One V3 case

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports =
    [
      # (inputs.nix-mineral + "/nix-mineral.nix")
      # ./nm-overrides.nix
      inputs.disko.nixosModules.disko

      ./hardware-configuration.nix
      ./disko.nix
    ]
    ++ (with nixos-raspberrypi.nixosModules; [
      raspberry-pi-5.base
      raspberry-pi-5.page-size-16k
      raspberry-pi-5.display-vc4
      raspberry-pi-5.bluetooth
    ]);

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [ ];

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------

  tensorfiles = {
    profiles = {
      headless.enable = true;
      packages-base.enable = true;
      # packages-extra.enable = true;
      # with-base-monitoring-exports.enable = true;
      # with-base-monitoring-exports.prometheus.exporters.node.openFirewall = false;
    };

    services.networking.networkmanager.enable = false;
    security.agenix.enable = true;

    tasks.nix-garbage-collect.enable = false;
    programs.nh.enable = true;

    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
      extraGroups = [ "input" ];
    };
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

  # nix-mineral.enable = true;
}
