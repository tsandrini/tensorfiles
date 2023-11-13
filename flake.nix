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
    treefmt-nix.url = "github:numtide/treefmt-nix";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://viperml.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
    ];
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

        imports = with inputs; [devenv.flakeModule treefmt-nix.flakeModule];

        flake = {
          lib = lib.tensorfiles;

          overlays = mapModules ./overlays import;

          nixosModules = import ./modules;

          nixosConfigurations = mapModules ./hosts mkHost;
        };

        perSystem = {
          system,
          config,
          ...
        }: let
          pkgs = mkNixpkgs inputs.nixpkgs system [];
        in {
          packages = mapModules ./pkgs (p: pkgs.callPackage p {inherit lib inputs;});

          devenv.shells = mapModules ./devenv (p: import p {inherit pkgs config inputs system;});

          treefmt = import ./treefmt.nix {inherit pkgs projectRoot;};
        };
      }
    );
}
