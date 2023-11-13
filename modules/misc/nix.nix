# --- modules/misc/nix.nix
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
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.misc.nix;
  _ = mkOverrideAtModuleLevel;
in {
  # TODO Modularize unstable/stable branches into an enum option
  options.tensorfiles.misc.nix = with types;
  with tensorfiles.types; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles defaults regarding nix
      language & nix package manager.
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      nix = {
        enable = _ true;
        checkConfig = _ true;
        nixPath = ["nixpkgs=${inputs.nixpkgs}"];
        package = _ pkgs.nixVersions.unstable;
        registry.nixpkgs.flake = _ inputs.nixpkgs;
        settings = {
          auto-optimise-store = _ true;
          trusted-substituters = [
            "https://devenv.cachix.org"
            "https://viperml.cachix.org"
            "https://cache.nixos.org"
            "https://nixpkgs-wayland.cachix.org"
            "https://hyprland.cachix.org"
          ];
          trusted-public-keys = [
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          ];
        };
        extraOptions = mkBefore ''
          experimental-features = nix-command flakes
          keep-outputs          = true
          keep-derivations      = true
        '';
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
