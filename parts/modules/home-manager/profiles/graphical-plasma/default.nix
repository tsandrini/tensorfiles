# --- parts/modules/home-manager/profiles/graphical-plasma/default.nix
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
  localFlake,
  inputs,
}: {
  config,
  lib,
  ...
}:
with builtins;
with lib; let
  inherit (localFlake.lib) mkOverrideAtHmProfileLevel;

  cfg = config.tensorfiles.hm.profiles.graphical-plasma;
  _ = mkOverrideAtHmProfileLevel;
in {
  options.tensorfiles.hm.profiles.graphical-plasma = with types; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');
  };

  imports = with inputs; [plasma-manager.homeManagerModules.plasma-manager];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (import ./rc2nix.nix)
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;

        hardware.nixGL.enable = _ true;

        programs = {
          newsboat.enable = _ true;
          pywal.enable = _ true;
          terminals.kitty.enable = _ true;
          browsers.firefox.enable = _ true;
          editors.emacs-doom.enable = _ true;
          #thunderbird.enable = _ true;
        };

        services = {
          pywalfox-native.enable = _ true;
        };
      };

      services.flameshot = {
        enable = _ true;
        settings = {
          General.showStartupLaunchMessage = _ false;
        };
      };

      services.rsibreak.enable = _ false;

      home.sessionVariables = {
        # Default programs
        BROWSER = _ "firefox";
        TERMINAL = _ "kitty";
        IDE = _ "emacs";
      };

      fonts.fontconfig.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
