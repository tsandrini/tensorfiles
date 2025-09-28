# --- flake-parts/modules/nixos/profiles/packages-base.nix
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
  # inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.packages-base;
in
# _ = mkOverrideAtProfileLevel;
{
  options.tensorfiles.profiles.packages-base = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the packages-base system profile.

      **packages-base layer**
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      environment.systemPackages = with pkgs; [
        # --- BASE UTILS ---
        openssl # Cryptographic library that implements the SSL and TLS protocols
        htop # An interactive process viewer
        jq # A lightweight and flexible command-line JSON processor
        killall
        vim # The most popular clone of the VI editor

        # --- BASE VCS UTILS ---
        git # Distributed version control system

        # --- NET UTILS ---
        dig # Domain name server
        netcat # Free TLS/SSL implementation
        wget # Tool for retrieving files using HTTP, HTTPS, and FTP
        curl # A command line tool for transferring files with URL syntax
        nmap # A free and open source utility for network discovery and security auditing

        # --- HW UTILS ---
        iotop # A tool to find out the processes doing the most IO

        # -- ARCHIVING UTILS --
        # rar # Utility for RAR archives
        # unrar # Utility for RAR archives # NOTE collision with rar
        unzip # An extraction utility for archives compressed in .zip format
        zip # Compressor/archiver for creating and modifying zipfiles
        xz # A general-purpose data compression software, successor of LZMA
        zstd # Zstandard real-time compression algorithm

        # -- MISC --

        # -- PACKAGING UTILS --

        # -- NIX UTILS --
        nix-health # Check the health of your Nix setup
        nix-fast-build # Combine the power of nix-eval-jobs with nix-output-monitor to speed-up your evaluation and building process
        nix-prefetch-scripts # Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes
        nix-output-monitor # Processes output of Nix commands to show helpful and pretty information
        deploy-rs # Multi-profile Nix-flake deploy tool
        disko # Declarative disk partitioning and formatting using nix
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
