# --- flake-parts/modules/nixos/profiles/graphical-dms-niri.nix
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
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.graphical-dms-niri;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.graphical-dms-niri = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  imports = [
    inputs.dms.nixosModules.greeter
    inputs.niri.nixosModules.niri
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.minimal.enable = _ true;
        services.networking.networkmanager.enable = _ true;
      };

      networking.nftables.enable = _ true;
      networking.firewall.enable = _ true;

      environment.systemPackages = [
        # -- GENERAL PACKAGES --
        pkgs.libnotify # A library that sends desktop notifications to a notification daemon
        pkgs.notify-desktop # Little application that lets you send desktop notifications with one command
        pkgs.wl-clipboard # Command-line copy/paste utilities for Wayland
        pkgs.maim # A command-line screenshot utility
        pkgs.xxdiff # Graphical file and directories comparator and merge tool
        pkgs.networkmanagerapplet # need this to configure L2TP ipsec

        # -- UTILS NEEDED FOR INFO-CENTER --
        pkgs.clinfo # Print all known information about all available OpenCL platforms and devices in the system
        pkgs.mesa-demos # Test utilities for OpenGL
        pkgs.vulkan-tools # Khronos official Vulkan Tools and Utilities
        pkgs.wayland-utils # Wayland utilities (wayland-info)
        pkgs.aha # ANSI HTML Adapter

        # -- DMS + NIRI stuff --
        pkgs.i2c-tools # Set of I2C tools for Linux
        pkgs.seahorse # Application for managing encryption keys and passwords in the GnomeKeyring
        # xwayland-satellite # Xwayland outside your Wayland compositor
      ];

      programs.xwayland = {
        enable = _ true;
        package = _ pkgs.xwayland-satellite;
      };

      programs.dank-material-shell.greeter = {
        enable = _ true;
        configHome = _ "/home/tsandrini"; # TODO probably find a better way to do this
        compositor.name = _ "niri";
      };

      programs.ssh.startAgent = _ false; # NOTE: using gnome agent

      # NOTE: It's required to have the niri executable in $PATH to populate
      # the wayland-sessions for the dms-greeter. Niri itself will then
      # load any configuration provided by HM without any issues, but we
      # have to traverse from NixOS -> HM somehow.
      programs.niri = {
        enable = _ true;
        package = _ pkgs.niri-unstable;
      };

      services.accounts-daemon.enable = _ true; # Required to persist user info
      services.dbus.enable = _ true;
      security.polkit.enable = _ true;
      programs.dconf.enable = _ true;
      services.udisks2.enable = _ true; # udisks2, a DBus service that allows applications to query and manipulate storage devices.
      services.gvfs.enable = _ true; # GVfs, a userspace virtual filesystem.

      xdg.portal = {
        enable = _ true;
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr # xdg-desktop-portal backend for wlroots
          pkgs.xdg-desktop-portal-gtk # Desktop integration portals for sandboxed apps
          pkgs.xdg-desktop-portal-gnome # Backend implementation for xdg-desktop-portal for the GNOME desktop environment
        ];
        config.common.default = [
          "wlr"
          "gtk"
        ];
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = _ "1";
        QT_QPA_PLATFORMTHEME = _ "gtk3";
        XDG_CURRENT_DESKTOP = _ "niri";
        XDG_SESSION_DESKTOP = _ "niri";
      };

      hardware.i2c.enable = _ true; # Required to control brightness of external monitors

      # Power management and additional power statistics
      services.power-profiles-daemon.enable = _ true;
      services.upower.enable = _ true;

      # Pass various secret management to gnome keyring and autounlock after login
      services.gnome.gnome-keyring.enable = _ true; # provides Secret Service + keyring daemon
      security.pam.services.greetd.enableGnomeKeyring = _ true;
      security.pam.services.login.enableGnomeKeyring = _ true;

      services.pcscd.enable = _ true; # needed for gpg pinentry

      # AUDIO stuff
      services.pipewire = {
        enable = _ true;
        alsa.enable = _ true;
        pulse.enable = _ true;
        jack.enable = _ true;
      };
      security.rtkit.enable = _ true; # realtime audio scheduling

      programs.kdeconnect.enable = _ true; # Required to expose ports
      systemd.user.services.niri-flake-polkit.enable = _ false;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
