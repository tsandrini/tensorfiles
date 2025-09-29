# --- flake-parts/modules/nixos/profiles/packages-extra.nix
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
{ localFlake }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.packages-extra;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.packages-extra = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the packages-extra system profile.

      **Packages-Extra layer**
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      environment.systemPackages = with pkgs; [
        # --- BASE UTILS ---
        stdenv.cc.cc # Basic C build toolchains
        binutils # Tools for manipulating binaries (linker, assembler, etc.) (wrapper script)
        calcurse # A calendar and scheduling application for the command line
        w3m # A text-mode web browser
        neofetch # A fast, highly customizable system info script
        cmake # Cross-platform, open-source build system generator
        gnumake # A tool to control the generation of non-source files from sources

        # --- BASE VCS UTILS ---
        gitu # TUI Git client inspired by Magit
        commitizen # Tool to create committing rules for projects, auto bump versions, and generate changelogs
        cz-cli # Commitizen command line utility
        gh # GitHub CLI tool

        # --- NET UTILS ---

        # --- HW UTILS ---
        dosfstools # Utilities for creating and checking FAT and VFAT file systems
        exfatprogs # exFAT filesystem userspace utilities
        udisks # A daemon, tools and libraries to access and manipulate disks, storage devices and technologies
        pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
        usbutils # Tools for working with USB devices, such as lsusb
        hw-probe # Probe for hardware, check operability and find drivers
        ntfs3g # FUSE-based NTFS driver with full write support

        # -- ARCHIVING UTILS --
        atool # Archive command line helper
        gzip # GNU zip compression program
        lz4 # Extremely fast compression algorithm
        lzip # A lossless data compressor based on the LZMA algorithm
        lzop # Fast file compressor
        p7zip # A new p7zip fork with additional codecs and improvements (forked from https://sourceforge.net/projects/p7zip/)
        rzip # Compression program
        lha # LHa is an archiver and compressor using the LZSS and Huffman encoding compression algorithms
        rar # Utility for RAR archives
        unrar # Utility for RAR archives # NOTE collision with rar

        # -- MISC --
        sqlite # A self-contained, serverless, zero-configuration, transactional SQL database engine
        sqlitebrowser # DB Browser for SQLite
        libarchive # Multi-format archive and compression library
        libbtbb # Bluetooth baseband decoding library
        adminer # Database management in a single PHP file

        # -- PACKAGING UTILS --
        rpm # RPM Package Manager
        dpkg # Debian package manager
        # nix-ld # Run unpatched dynamic binaries on NixOS
        appimage-run # Run unpatched AppImages on NixOS
        libappimage # Implements functionality for dealing with AppImage files

        # -- NIX UTILS --
        # nix-index # A files database for nixpkgs
        # TODO: https://github.com/NixOS/nixpkgs/issues/331748
        # nix-du # A tool to determine which gc-roots take space in your nix store
        nix-tree # Interactively browse a Nix store paths dependencies
        nix-update # Swiss-knife for updating nix packages
        nix-prefetch-scripts # Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes
        # nix-serve # A utility for sharing a Nix store as a binary cache # NOTE conflict with serve-ng
        nix-serve-ng # A drop-in replacement for nix-serve that's faster and more stable
        nixos-shell # Spawns lightweight nixos vms in a shell
        # nh # Yet another nix cli helper
        cachix # Command-line client for Nix binary cache hosting https://cachix.org
        devenv # Fast, Declarative, Reproducible, and Composable Developer Environments
        nixos-anywhere # Install nixos everywhere via ssh
      ];

      programs.nix-ld.enable = _ true; # Run unpatched dynamic binaries on NixOS
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
