# --- parts/hosts/default.nix
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
{
  lib,
  inputs,
  withSystem,
  config,
  ...
}:
let
  inherit (inputs.flake-parts.lib) importApply;

  mkHost =
    args: hostName:
    {
      extraSpecialArgs ? { },
      extraModules ? [ ],
      extraOverlays ? [ ],
      withHomeManager ? false,
      hostImportArgs ? {
        inherit inputs;
      },
      ...
    }:
    let
      baseSpecialArgs = {
        inherit (args) system;
        inherit inputs hostName;
      } // extraSpecialArgs;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (args) system;
      specialArgs = baseSpecialArgs // {
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
          (importApply ./${hostName} hostImportArgs)
        ]
        ++ extraModules
        # Disabled by default, therefore load every module and enable via attributes
        # instead of imports
        ++ (lib.attrValues config.flake.nixosModules)
        ++ (
          if withHomeManager then
            [
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
          else
            [ ]
        );
    };
in
{
  flake.nixosConfigurations = {
    jetbundle = withSystem "x86_64-linux" (
      args:
      mkHost args "jetbundle" {
        withHomeManager = true;
        extraOverlays = with inputs; [
          nix-topology.overlays.default
          emacs-overlay.overlays.default
          nur.overlays.default
          # neovim-nightly-overlay.overlays.default
          # (final: _prev: { nur = import inputs.nur { pkgs = final; }; })
        ];
        extraModules = with inputs; [
          nur.modules.nixos.default
          nix-topology.nixosModules.default
        ];
      }
    );
    remotebundle = withSystem "x86_64-linux" (
      args:
      mkHost args "remotebundle" {
        withHomeManager = true;
        extraOverlays = with inputs; [
          nix-topology.overlays.default
          # nur.overlays.default
          # neovim-nightly-overlay.overlays.default
        ];
        extraModules = with inputs; [
          nix-topology.nixosModules.default
          # nur.modules.nixos.default
        ];
        hostImportArgs = {
          inherit inputs;
          inherit (config.agenix) secretsPath;
        };
      }
    );
    spinorbundle = withSystem "x86_64-linux" (
      args:
      mkHost args "spinorbundle" {
        withHomeManager = true;
        extraOverlays = with inputs; [
          nix-topology.overlays.default
          emacs-overlay.overlays.default
          nur.overlays.default
          # neovim-nightly-overlay.overlays.default
          # (final: _prev: { nur = import inputs.nur { pkgs = final; }; })
        ];
        extraModules = with inputs; [
          nur.modules.nixos.default
          nix-topology.nixosModules.default
        ];
      }
    );
  };
}
