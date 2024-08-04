# --- flake-parts/homes/tsandrini@jetbundle/default.nix
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
{ pkgs, ... }:
{
  tensorfiles.hm = {
    profiles.graphical-xmonad.enable = true;
    # enable patches since we arent on NixOS
    hardware.nixGL.programPatches.enable = true;
    hardware.nixGL.enable = true;

    # security.agenix.enable = true;
    programs.pywal.enable = true;
    programs.shadow-nix.enable = true;
    programs.spicetify.enable = true;
    services.pywalfox-native.enable = true;
    services.keepassxc.enable = true;
  };

  programs.shadow-client.forceDriver = "iHD";
  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  home.username = "tsandrini";
  home.homeDirectory = "/home/tsandrini";
  home.sessionVariables = {
    DEFAULT_USERNAME = "tsandrini";
    DEFAULT_MAIL = "tomas.sandrini@seznam.cz";
  };

  home.packages = with pkgs; [
    thunderbird # A full-featured e-mail client
    beeper # Universal chat app.
    armcord # Lightweight, alternative desktop client for Discord
    anki # Spaced repetition flashcard program
    libreoffice # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
    texlive.combined.scheme-medium # TeX Live environment
    zotero # Collect, organize, cite, and share your research sources
    lapack # openblas with just the LAPACK C and FORTRAN ABI
    ungoogled-chromium # An open source web browser from Google, with dependencies on Google web services removed
    zoom-us # Player for Z-Code, TADS and HUGO stories or games

    slack # Desktop client for Slack
    signal-desktop # Private, simple, and secure messenger

    todoist # Todoist CLI Client
    todoist-electron # The official Todoist electron app

    mpv # General-purpose media player, fork of MPlayer and mplayer2
    zathura # A highly customizable and functional PDF viewer

    # NOTE: the packages below are typically part of a NixOS base installation
    # under root, hardware related utils should probably be installed manually
    # using the default package manager of the system instead of home-manager,
    # so those are omitted

    # --- BASE UTILS ---
    htop # An interactive process viewer
    jq # A lightweight and flexible command-line JSON processor
    killall
    vim # The most popular clone of the VI editor
    calcurse # A calendar and scheduling application for the command line
    w3m # A text-mode web browser
    neofetch # A fast, highly customizable system info script

    # ARCHIVING UTILS --
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
