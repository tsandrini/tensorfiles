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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    nur.url = "github:nix-community/NUR";

    arkenfox-user-js = {
      url = "github:arkenfox/user.js";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    inherit (lib.tensorfiles.modules) mapModules mkPackages mkHost mkShells;

    # These assignments are optional and only serve to change the default values
    # (that being `root` and `./secrets` -- if you don't plan on using any secrets
    # backend you can simply ignore this), meaning that
    # you can change or even delete them, however, the projectRoot variable is
    # required, so please keep that one.
    user = "tsandrini";

    lib = nixpkgs.lib.extend (self: _super: {
      tensorfiles = import ./lib {
        inherit inputs user;
        pkgs = nixpkgs;
        lib = self;
      };
    });
  in {
    lib = lib.tensorfiles;

    overlays = mapModules ./overlays import;

    packages = mkPackages ./pkgs {};

    nixosModules = mapModules ./modules import;

    nixosConfigurations = mapModules ./hosts mkHost;

    devShells = mkShells ./shells {};
  };
}
