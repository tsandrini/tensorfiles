# --- flake-parts/modules/nixos/profiles/graphical-plasma5.nix
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
{ localFlake, inputs }:
{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.graphical-plasma5;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.graphical-plasma5 = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.headless.enable = _ true;
      };

      environment.systemPackages = with pkgs; [
        libnotify
        notify-desktop

        wl-clipboard
        maim

        wireshark

        # KDE stuff
        ark # Graphical file compression/decompression utility
        haruna # Open source video player built with Qt/QML and libmpv
        kate # Advanced text editor
        libsForQt5.kcalc # Scientific calculator
        kdiff3 # Compares and merges 2 or 3 files or directories
        krename # A powerful batch renamer for KDE
        krusader # Norton/Total Commander clone for KDE
        libsForQt5.filelight # Disk usage statistics
        libsForQt5.kweather
        libsForQt5.kweathercore
        libsForQt5.quazip # Provides access to ZIP archives from Qt programs
        libsForQt5.ksshaskpass
        libsForQt5.accounts-qt # Qt library for accessing the online accounts database
        libsForQt5.calendarsupport
        libsForQt5.kaccounts-providers # Online account providers
        libsForQt5.kaccounts-integration # Online accounts integration
        libsForQt5.kdeplasma-addons
        libsForQt5.plasma-browser-integration
        libsForQt5.kaddressbook # KDE contact manager
        libsForQt5.merkuro # A calendar application using Akonadi to sync with external services

        libsForQt5.kmail # Mail client
        libsForQt5.kmailtransport
        libsForQt5.kmail-account-wizard

        libsForQt5.akonadi
        libsForQt5.akonadi-calendar
        libsForQt5.akonadi-calendar-tools
        libsForQt5.akonadi-contacts
        libsForQt5.akonadi-import-wizard
        libsForQt5.akonadi-mime
        libsForQt5.akonadi-notes
        libsForQt5.akonadi-search
        libsForQt5.akonadiconsole
        libsForQt5.kdepim-runtime
        libsForQt5.kdepim-addons
        libsForQt5.libkdepim

        krita # A free and open source painting application
        libsForQt5.kdenlive # Video editor
        libsForQt5.kcolorpicker # Qt based Color Picker with popup menu
        libsForQt5.kcolorchooser
        libsForQt5.kolourpaint # Paint program
        libsForQt5.knotes # Popup notes
        libsForQt5.kalarm # Personal alarm scheduler
        libsForQt5.kamoso # A simple and friendly program to use your camera
        libsForQt5.kruler # Screen ruler
        libsForQt5.kclock # Clock app for plasma mobile
        okteta # A hex editor
        libsForQt5.elisa # A simple media player for KDE
        libsForQt5.kmag # A small Linux utility to magnify a part of the screen
        libsForQt5.itinerary

        #libsForQt5.bismuth # A dynamic tiling extension for KWin
        # libsForQt5.polonium # Auto-tiler that uses KWin 5.27+ tiling functionality
        inputs.self.packages.${system}.polonium-nightly
      ];

      services.xserver.enable = _ true;
      services.displayManager.sddm.enable = _ true;
      services.xserver.desktopManager.plasma6.enable = _ true;
      services.xserver.displayManager.defaultSession = _ "plasma";
      programs.kdeconnect.enable = _ true;

      programs.partition-manager.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
