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
  self,
  projectPath,
  withSystem,
  config,
  ...
}: let
  mkHost = args: hostName: {
    extraSpecialArgs ? {},
    extraModules ? [],
    extraOverlays ? [],
    withHomeManager ? false,
    ...
  }: let
    baseSpecialArgs =
      {
        inherit (args) system self' inputs';
        inherit inputs self hostName projectPath;
        inherit (config.secrets) secretsPath pubkeys;
      }
      // extraSpecialArgs;
  in
    lib.nixosSystem {
      inherit (args) system;
      specialArgs =
        baseSpecialArgs
        // {
          inherit lib hostName;
          host.hostName = hostName;
        };
      modules =
        [
          {
            nixpkgs.overlays = extraOverlays;
            nixpkgs.config.allowUnfree = true;
            networking.hostName = hostName;
          }
          ./${hostName}
        ]
        ++ extraModules
        # Disabled by default, therefore load every module and enable via attributes
        # instead of imports
        ++ (lib.attrValues config.flake.nixosModules)
        ++ (
          if withHomeManager
          then [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = baseSpecialArgs;
                sharedModules = lib.attrValues config.flake.homeModules;
              };
            }
          ]
          else []
        );
    };
in {
  flake.nixosConfigurations = {
    spinorbundle = withSystem "x86_64-linux" (args:
      mkHost args "spinorbundle" {
        withHomeManager = true;
        extraOverlays = with inputs; [
          emacs-overlay.overlay
          neovim-nightly-overlay.overlay
          (final: _prev: {
            nur = import inputs.nur {pkgs = final;};
          })
        ];
      });
    jetbundle = withSystem "x86_64-linux" (args:
      mkHost args "jetbundle" {
        withHomeManager = true;
        extraOverlays = with inputs; [
          emacs-overlay.overlay
          neovim-nightly-overlay.overlay
          (final: _prev: {
            nur = import inputs.nur {pkgs = final;};
          })
          (final: prev: {
            polonium = prev.libsForQt5.polonium.overrideAttrs (_old: {
              src = final.fetchFromGitHub {
                owner = "zeroxoneafour";
                repo = "polonium";
                rev = "dbb86e5e829d8ae57caf78cd3ef0606fdc1fbca5";
                hash = "sha256-fZgNOcOq+owmqtplwnxeOIQpWmrga/WitCNCj89O5XA=";
              };
            });
          })
        ];
      });
  };
}
