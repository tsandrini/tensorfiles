# --- parts/modules/nixos/profiles/headless.nix
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
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
with builtins;
with lib; let
  cfg = config.tensorfiles.profiles.headless;
  _ = mkOverride 400;
in {
  options.tensorfiles.profiles.headless = with types; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the headless system profile.

      **Headless layer** builds on top of the minimal layer and adds other
      server-like functionality like simple shells, basic networking for remote
      access and simple editors.
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.minimal.enable = _ true;

        security.agenix.enable = _ true;

        services.networking.networkmanager.enable = _ true;
        services.networking.ssh.enable = _ true;

        system.users = {
          enable = _ true;
          usersSettings = {
            "root" = {};
          };
        };
      };

      environment.systemPackages = with pkgs; [
        inputs.nh.packages.${system}.default
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);
}
