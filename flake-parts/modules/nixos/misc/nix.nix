# --- flake-parts/modules/nixos/misc/nix.nix
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
{ localFlake, inputs }:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkBefore
    mkEnableOption
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.misc.nix;
  _ = mkOverrideAtModuleLevel;
in
{
  options.tensorfiles.misc.nix = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles defaults regarding nix
      language & nix package manager.
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      nix = {
        enable = _ true;
        checkConfig = _ true;
        nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
        # NOTE: Using lix instead, so we'll leave the default settings
        #       that will get overridden by the lix overlay
        package = _ pkgs.nixVersions.latest;
        registry.nixpkgs.flake = _ inputs.nixpkgs;
        settings = {
          auto-optimise-store = _ true;
          builders-use-substitutes = _ true;
          trusted-substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org/"
            "https://devenv.cachix.org"
            "https://tsandrini.cachix.org"
            "https://nixpkgs-wayland.cachix.org"
            "https://nix-gaming.cachix.org"
            "https://cache.lix.systems"
            # "https://hyprland.cachix.org"
            # "https://anyrun.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "tsandrini.cachix.org-1:t0AzIUglIqwiY+vz/WRWXrOkDZN8TwY3gk+n+UDt4gw="
            "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
            "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
            "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
            # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            # "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
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

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
