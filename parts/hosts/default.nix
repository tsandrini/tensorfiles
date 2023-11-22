# --- parts/hosts/default.nix
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
  inputs,
  projectPath,
  secretsPath,
  withSystem,
  config,
  ...
}: let
  mkHost = args: hostName: {
    extraSpecialArgs ? {},
    extraModules ? [],
  }:
    lib.nixosSystem {
      inherit (args) system pkgs;
      specialArgs =
        {
          inherit (args) system;
          inherit inputs lib hostName projectPath secretsPath;
          # TODO also maybe do something about this
          secretsAttrset =
            if builtins.pathExists (secretsPath + "/secrets.nix")
            then (import (secretsPath + "/secrets.nix"))
            else {};
          host.hostName = hostName;
          # TODO REMOVE THIS TODO REMOVE THIS
          user = "tsandrini"; # TODO REMOVE THIS
        }
        // extraSpecialArgs;
      modules =
        [
          {
            nixpkgs.pkgs = lib.mkDefault args.pkgs;
            networking.hostName = hostName;
          }
          ./${hostName}
        ]
        ++ extraModules
        # Disabled by default, therefore load every module and enable via attributes
        # instead of imports
        ++ (lib.attrValues config.flake.nixosModules);
    };
in {
  flake.nixosConfigurations = {
    spinorbundle = withSystem "x86_64-linux" (args:
      mkHost args "spinorbundle" {
        extraModules = with inputs; [
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nur.nixosModules.nur
        ];
      });
  };
}
