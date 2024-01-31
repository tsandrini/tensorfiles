# --- parts/modules/home-manager/programs/spicetify.nix
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
  system,
  ...
}:
with builtins;
with lib; let
  cfg = config.tensorfiles.hm.programs.spicetify;

  spicePkgs = inputs.spicetify-nix.packages.${system}.default;
in {
  options.tensorfiles.hm.programs.spicetify = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');
  };

  imports = with inputs; [spicetify-nix.homeManagerModule];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.spicetify = {
        enable = true;
        theme = spicePkgs.themes.catppuccin;
        colorScheme = "mocha";

        enabledExtensions = with spicePkgs.extensions; [
          fullAppDisplay
          shuffle # shuffle+ (special characters are sanitized out of ext names)
          keyboardShortcut
          powerBar
          history
        ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);
}
