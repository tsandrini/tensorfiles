# --- parts/modules/nixos/profiles/graphical-plasma6.nix
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
with builtins;
with lib;
let
  inherit (localFlake.lib) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.graphical-plasma6;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.graphical-plasma6 = with types; {
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
        # -- GENERAL PACKAGES --
        libnotify # A library that sends desktop notifications to a notification daemon
        notify-desktop # Little application that lets you send desktop notifications with one command
        wl-clipboard # Command-line copy/paste utilities for Wayland
        maim # A command-line screenshot utility

        wireshark # Powerful network protocol analyzer
        pgadmin4-desktopmode # Administration and development platform for PostgreSQL. Desktop Mode
        mqttui # Terminal client for MQTT
        mqttx # Powerful cross-platform MQTT 5.0 Desktop, CLI, and WebSocket client tools

        # -- UTILS NEEDED FOR INFO-CENTER --
        clinfo # Print all known information about all available OpenCL platforms and devices in the system
        glxinfo # Test utilities for OpenGL
        vulkan-tools # Khronos official Vulkan Tools and Utilities
        wayland-utils # Wayland utilities (wayland-info)
        aha # ANSI HTML Adapter

        # -- KDE PACKAGES --
        kdePackages.ark # Graphical file compression/decompression utility
        haruna # Open source video player built with Qt/QML and libmpv
        kdePackages.kate # Advanced text editor
        kdePackages.kcalc # Scientific calculator
        kdiff3 # Compares and merges 2 or 3 files or directories
        krename # A powerful batch renamer for KDE
        krusader # Norton/Total Commander clone for KDE
        kdePackages.filelight # Disk usage statistics
        kdePackages.kweather
        kdePackages.kweathercore
        kdePackages.quazip # Provides access to ZIP archives from Qt programs
        kdePackages.ksshaskpass
        kdePackages.accounts-qt # Qt library for accessing the online accounts database
        kdePackages.calendarsupport
        kdePackages.kaccounts-providers # Online account providers
        kdePackages.kaccounts-integration # Online accounts integration
        kdePackages.kdeplasma-addons
        kdePackages.plasma-browser-integration
        kdePackages.kaddressbook # KDE contact manager
        kdePackages.merkuro # A calendar application using Akonadi to sync with external services

        kdePackages.kmail # Mail client
        kdePackages.kmailtransport
        kdePackages.kmail-account-wizard

        kdePackages.akonadi
        kdePackages.akonadi-calendar
        kdePackages.akonadi-calendar-tools
        kdePackages.akonadi-contacts
        kdePackages.akonadi-import-wizard
        kdePackages.akonadi-mime
        kdePackages.akonadi-notes
        kdePackages.akonadi-search
        kdePackages.akonadiconsole
        kdePackages.kdepim-runtime
        kdePackages.kdepim-addons
        kdePackages.libkdepim

        krita # A free and open source painting application
        kdePackages.kdenlive # Video editor
        kdePackages.kcolorpicker # Qt based Color Picker with popup menu
        kdePackages.kcolorchooser
        kdePackages.kolourpaint # Paint program
        kdePackages.knotes # Popup notes
        kdePackages.kalarm # Personal alarm scheduler
        # kdePackages.kamoso # A simple and friendly program to use your camera
        kdePackages.kruler # Screen ruler
        kdePackages.kclock # Clock app for plasma mobile
        okteta # A hex editor
        kdePackages.elisa # A simple media player for KDE
        kdePackages.kmag # A small Linux utility to magnify a part of the screen
        kdePackages.itinerary

        #kdePackages.bismuth # A dynamic tiling extension for KWin
        # kdePackages.polonium # Auto-tiler that uses KWin 5.27+ tiling functionality
        inputs.self.packages.${system}.polonium-nightly
      ];

      services.xserver.enable = _ true;
      services.displayManager.sddm.enable = _ true;
      services.desktopManager.plasma6.enable = _ true;
      # services.xserver.displayManager.defaultSession = _ "plasma";
      programs.kdeconnect.enable = _ true;

      programs.partition-manager.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
