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
{ config, lib, pkgs, inputs, ... }:
with builtins;
with lib;
let
  cfg = config.tensorfiles.misc.nix;
  _ = mkOverride 500;
in {
  # TODO Modularize unstable/stable branches into an enum option
  options.tensorfiles.misc.nix = with types; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles defaults regarding nix
      language & nix package manager.
    '');
  };

  config = mkIf cfg.enable (mkMerge [({
    nix = {
      enable = _ true;
      checkConfig = _ true;
      package = _ pkgs.nixVersions.unstable;
      registry.nixpkgs.flake = _ inputs.nixpkgs;
      settings.auto-optimise-store = _ true;
      extraOptions = mkBefore ''
        experimental-features = nix-command flakes
        keep-outputs          = true
        keep-derivations      = true
      '';
    };
  })]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}
