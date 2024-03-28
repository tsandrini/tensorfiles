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
    # Base dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    # Development (devenv and treefmt dependencies)
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Project specific dependencies
    disko = {
      url = "github:nix-community/disko";
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

    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    nur.url = "github:nix-community/NUR";

    arkenfox-user-js = {
      url = "github:arkenfox/user.js";
      flake = false;
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      # nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    };

    kitty-scrollback-nvim = {
      url = "github:mikesmithgh/kitty-scrollback.nvim";
      flake = false;
    };

    # TODO some serious maintenance sheningans
    shadow-nix = {
      url = "github:Exaltia/shadow-nix";
      flake = false;
    };

    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   #inputs.nixpkgs.follows = "nixpkgs";
    # };
    # anyrun = {
    #   url = "github:Kirottu/anyrun";
    #   #inputs.nixpkgs.follows = "nixpkgs";
    # };
    # ags = {
    #   url = "github:Aylur/ags";
    #   #inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # Here you can add additional binary cache substituers that you trust.
  # There are also some sensible default caches commented out that you
  # might consider using.
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org/"
      "https://devenv.cachix.org"
      "https://tsandrini.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://nix-gaming.cachix.org"
      # "https://hyprland.cachix.org"
      # "https://anyrun.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "tsandrini.cachix.org-1:t0AzIUglIqwiY+vz/WRWXrOkDZN8TwY3gk+n+UDt4gw="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      # "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
    ];
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs) nixpkgs;
      inherit (lib.tensorfiles) mapModules flatten;

      # You should ideally use relative paths in each individual part from ./parts,
      # however, if needed you can use the `projectPath` variable that is passed
      # to every flakeModule to properly anchor your absolute paths.
      projectPath = ./.;

      # We extend the base <nixpkgs> library with our own custom helpers as well
      # as override any of the nixpkgs default functions that we'd like
      # to override. This instance is then passed to every part in ./parts so that
      # you can use it in your custom modules
      lib = nixpkgs.lib.extend (
        self: _super: {
          tensorfiles = import ./lib {
            inherit inputs projectPath;
            pkgs = nixpkgs;
            lib = self;
          };
        }
      );
      specialArgs = {
        inherit lib projectPath;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs specialArgs; } {
      # We recursively traverse all of the flakeModules in ./parts and import only
      # the final modules, meaning that you can have an arbitrary nested structure
      # that suffices your needs. For example
      #
      # - ./parts
      #   - modules/
      #     - nixos/
      #       - myNixosModule1.nix
      #       - myNixosModule2.nix
      #       - default.nix
      #     - home-manager/
      #       - myHomeModule1.nix
      #       - myHomeModule2.nix
      #       - default.nix
      #     - sharedModules.nix
      #    - pkgs/
      #      - myPackage1.nix
      #      - myPackage2.nix
      #      - default.nix
      #    - mySimpleModule.nix
      imports = flatten (mapModules ./parts (x: x));

      # We use the default `systems` defined by the `nix-systems` flake, if you
      # need any additional systems, simply add them in the following manner
      #
      # `systems = (import inputs.systems) ++ [ "armv7l-linux" ];`
      systems = import inputs.systems;
      flake.lib = lib.tensorfiles;

      # Since the official flakes output schema is unfortunately very limited
      # you can enable the debug mode if you need to inspect certain outputs
      # of your flake. Simply
      #
      # 1. uncomment the following line
      # 2. hop into a repl from the project root - `nix repl`
      # 3. load the flake - `:lf .`
      #
      # After that you can inspect the flake from the root attribute `debug.flake`
      # debug = true;
    };
}
