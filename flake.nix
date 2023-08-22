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
    impermanence.url = "github:nix-community/impermanence";
    agenix.url = "github:ryantm/agenix";

    nur.url = "github:nix-community/NUR";

    arkenfox-user-js = {
      url = "github:arkenfox/user.js";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (lib.tensorfiles.modules) mapModules mkPkgs mkHost;

      user = "tsandrini";

      lib = nixpkgs.lib.extend (self: super: {
        tensorfiles = import ./lib {
          inherit inputs user;
          pkgs = nixpkgs;
          lib = self;
        };
      });

    in {
      lib = lib.tensorfiles;

      overlays = mapModules ./overlays import;

      packages = lib.genAttrs [ "x86_64-linux" ] (system:
        let systemPkgs = mkPkgs nixpkgs system [ ];
        in mapModules ./pkgs
        (p: systemPkgs.callPackage p { inherit lib inputs; }));

      nixosModules = mapModules ./modules import;

      nixosProfiles = mapModules ./profiles import;

      nixosConfigurations = mapModules ./hosts mkHost;
    };
}
