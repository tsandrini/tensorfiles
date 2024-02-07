# --- parts/modules/nixos/profiles/minimal.nix
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
{localFlake}: {
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit (localFlake.lib) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.minimal;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.profiles.minimal = with types; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the minimal system profile.

      **Minimal layers** builds on top of the base layer and creates a
      minimal bootable system. It isn't targeted to posses any other functionality,
      for example if you'd like remote access and more of server-like features,
      use the headless profile that build on top of this one.
    '');
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.base.enable = _ true;

        tasks.nix-garbage-collect.enable = _ true;
        tasks.system-autoupgrade.enable = _ true;
      };

      time.timeZone = _ "Europe/Prague";
      i18n.defaultLocale = _ "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = _ "cs_CZ.UTF-8";
        LC_IDENTIFICATION = _ "cs_CZ.UTF-8";
        LC_MEASUREMENT = _ "cs_CZ.UTF-8";
        LC_MONETARY = _ "cs_CZ.UTF-8";
        LC_NAME = _ "cs_CZ.UTF-8";
        LC_NUMERIC = _ "cs_CZ.UTF-8";
        LC_PAPER = _ "cs_CZ.UTF-8";
        LC_TELEPHONE = _ "cs_CZ.UTF-8";
        LC_TIME = _ "cs_CZ.UTF-8";
      };

      console = {
        enable = _ true;
        useXkbConfig = _ true;
        font = _ "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
      };

      environment.systemPackages = with pkgs; [
        # --- BASE UTILS ---
        htop # An interactive process viewer
        jq # A lightweight and flexible command-line JSON processor
        killall
        vim # The most popular clone of the VI editor
        calcurse # A calendar and scheduling application for the command line
        w3m # A text-mode web browser
        neofetch # A fast, highly customizable system info script

        # --- NET UTILS ---
        dig # Domain name server
        netcat # Free TLS/SSL implementation
        wget # Tool for retrieving files using HTTP, HTTPS, and FTP
        curl # A command line tool for transferring files with URL syntax
        nmap # A free and open source utility for network discovery and security auditing

        # --- HW UTILS ---
        dosfstools # Utilities for creating and checking FAT and VFAT file systems
        exfatprogs # exFAT filesystem userspace utilities
        udisks # A daemon, tools and libraries to access and manipulate disks, storage devices and technologies
        pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
        usbutils # Tools for working with USB devices, such as lsusb
        iotop # A tool to find out the processes doing the most IO
        hw-probe # Probe for hardware, check operability and find drivers
        ntfs3g # FUSE-based NTFS driver with full write support

        # -- ARCHIVING UTILS --
        atool # Archive command line helper
        gzip # GNU zip compression program
        lz4 # Extremely fast compression algorithm
        lzip # A lossless data compressor based on the LZMA algorithm
        lzop # Fast file compressor
        p7zip # A new p7zip fork with additional codecs and improvements (forked from https://sourceforge.net/projects/p7zip/)
        rar # Utility for RAR archives
        # unrar # Utility for RAR archives # NOTE collision with rar
        rzip # Compression program
        unzip # An extraction utility for archives compressed in .zip format
        xz # A general-purpose data compression software, successor of LZMA
        zip # Compressor/archiver for creating and modifying zipfiles
        zstd # Zstandard real-time compression algorithm

        # -- MISC --
        sqlite # A self-contained, serverless, zero-configuration, transactional SQL database engine
        sqlitebrowser # DB Browser for SQLite
        libarchive # Multi-format archive and compression library
        libbtbb # Bluetooth baseband decoding library

        # -- NIX UTILS --
        nix-index # A files database for nixpkgs
        nix-du # A tool to determine which gc-roots take space in your nix store
        nix-tree # Interactively browse a Nix store paths dependencies
        nix-health # Check the health of your Nix setup
        nix-update # Swiss-knife for updating nix packages
        # nix-serve # A utility for sharing a Nix store as a binary cache # NOTE conflict with serve-ng
        nix-serve-ng # A drop-in replacement for nix-serve that's faster and more stable
        nix-prefetch-scripts # Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes
        nix-output-monitor # Processes output of Nix commands to show helpful and pretty information
        nh # Yet another nix cli helper
        disko # Declarative disk partitioning and formatting using nix
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [tsandrini];
}
