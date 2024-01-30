# --- modules/programs/wayland/ags.nix
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
  inputs,
  ...
}:
with builtins;
with lib; let
  cfg = config.tensorfiles.programs.wayland.ags;
  _ = mkOverride 500;
in {
  options.tensorfiles.programs.wayland.ags = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the ags.nix app launcher


       https://github.com/Aylur/ags
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {});
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      services.upower.enable = _ true;
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: {
        # Since this module is completely isolated and single purpose
        # (meaning that the only possible place to import it from tensorfiles
        # is here) we can leave the import call here
        imports = [inputs.ags.homeManagerModules.default];

        programs.ags = {
          enable = _ true;
          # extraPackages = with pkgs; [
          #   sassc
          #   swww
          #   brightnessctl
          #   slurp
          # ];
        };
      });
    })
    # |----------------------------------------------------------------------| #
  ]);
}
