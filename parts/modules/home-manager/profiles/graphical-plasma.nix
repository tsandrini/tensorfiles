# --- parts/modules/home-manager/profiles/graphical-plasma.nix
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
  self,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) mkOverrideAtHmProfileLevel;

  cfg = config.tensorfiles.hm.profiles.graphical-plasma;
  _ = mkOverrideAtHmProfileLevel;
in {
  options.tensorfiles.hm.profiles.graphical-plasma = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;

        hardware.nixGL.enable = _ true;

        # not needed, since plasma sets it up itself
        # misc.gtk.enable = _ true;

        programs = {
          newsboat.enable = _ true;
          # dmenu.enable = _ true;
          pywal.enable = _ true;
          terminals.kitty.enable = _ true;
          browsers.firefox.enable = _ true;
          editors.emacs-doom.enable = _ true;
        };

        services = {
          # dunst.enable = _ true;
          pywalfox-native.enable = _ true;

          x11 = {
            # picom.enable = _ true;
            # redshift.enable = _ true;
            # window-managers.plasma6.enable = _ true;
          };
        };
      };

      services.flameshot = {
        enable = _ true;
        settings = {
          General.showStartupLaunchMessage = _ false;
        };
      };

      programs.firefox.profiles.default.extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        plasma-integration
      ];

      home.sessionVariables = {
        # Default programs
        BROWSER = "firefox";
        TERMINAL = "kitty";
        IDE = "emacs";
      };

      home.packages = with pkgs; [
        # arandr
        mpv
        # feh
        zathura
        libsForQt5.polonium
        libsForQt5.lightly
        catppuccin-kde

        haruna
        partition-manager
        libsForQt5.ark
        libsForQt5.ksshaskpass
        krita
        libsForQt5.kdenlive
        libsForQt5.filelight
        libsForQt5.kcolorchooser
        libsForQt5.kate
        libsForQt5.kolourpaint
        libsForQt5.kamoso
        libsForQt5.kruler
        libsForQt5.elisa
        libsForQt5.kmag
        libsForQt5.kalarm
        libsForQt5.kweather
        okteta
        libsForQt5.itinerary
        libsForQt5.kclock
        rsibreak
        libsForQt5.merkuro
        libsForQt5.kcalc
        libsForQt5.kdeplasma-addons
        libsForQt5.plasma-browser-integration
      ];

      fonts.fontconfig.enable = _ true;

      # services.network-manager-applet.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
