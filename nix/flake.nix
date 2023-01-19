# --- flake.nix
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
  description = "tsandrini's fully covariant tensorfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      user = "tsandrini";
      lib = nixpkgs.lib;

      tensorlib = import ./lib {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs home-manager user;
      };

      findModules = dir:
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: type:
            if type == "regular" then [{
              name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
              value = import (dir + "/${name}");
            }] else if (builtins.readDir (dir + "/${name}")) ? "default.nix" then [{
              inherit name;
              value = import (dir + "/${name}");
            }] else
              findModules (dir + "/${name}")) (builtins.readDir dir)));

      mkHost = name:
        let
          system = lib.removeSuffix "\n" (builtins.readFile (./hosts + "/${name}/system"));
        in lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs user;
            host.hostName = name;
          };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            { networking.hostName = name; }
            ( ./hosts + "/${name}" )
          ];
        };
    in
      {
        nixosModules = builtins.listToAttrs (findModules ./modules);

        nixosProfiles = builtins.listToAttrs (findModules ./profiles);

        nixosRoles = import ./roles;

        nixosConfigurations = (
          let hosts = builtins.attrNames (builtins.readDir ./hosts);
          in lib.genAttrs hosts mkHost
        );
      };
}
