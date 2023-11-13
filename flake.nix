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
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} (
      let
        inherit (inputs) nixpkgs systems;
        inherit (lib.tensorfiles.modules) mapModules mkNixpkgs mkHost;

        # These assignments are optional and only serve to change the default values
        # (that being `root` and `./secrets` -- if you don't plan on using any secrets
        # backend you can simply ignore this), meaning that
        # you can change or even delete them, however, the projectRoot variable is
        # required, so please keep that one.
        user = "tsandrini";
        projectRoot = ./.;
        secretsPath = projectRoot + "/secrets";

        lib = nixpkgs.lib.extend (self: _super: {
          tensorfiles = import ./lib {
            inherit inputs user projectRoot secretsPath;
            pkgs = nixpkgs;
            lib = self;
          };
        });
      in {
        systems = import systems;

        imports = with inputs; [devenv.flakeModule];

        flake = {
          lib = lib.tensorfiles;

          overlays = mapModules ./overlays import;

          nixosModules = mapModules ./modules import;

          nixosConfigurations = mapModules ./hosts mkHost;
        };

        perSystem = {system, ...}: let
          pkgs = mkNixpkgs inputs.nixpkgs system [];
        in {
          packages = mapModules ./pkgs (p: pkgs.callPackage p {inherit lib inputs;});

          devenv.shells = mapModules ./devenv import;
        };
      }
    );
}
