# --- flake-parts/modules/nixos/profiles/packages-graphical-extra.nix
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

  cfg = config.tensorfiles.profiles.packages-graphical-extra;
  # _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.packages-graphical-extra = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the packages-graphical-extra system profile.

      **Packages-graphical-extra layer**
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      environment.systemPackages = with pkgs; [
        # --- BROWSERS ---
        ungoogled-chromium # An open source web browser from Google, with dependencies on Google web services removed

        # --- DOCUMENTS & OFFICE ---
        anki # Spaced repetition flashcard program
        gnucash # Free software for double entry accounting
        libreoffice # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
        obsidian # A knowledge base that works on top of a local folder of plain text Markdown files
        texlive.combined.scheme-full # TeX Live environment
        zathura # A highly customizable and functional PDF viewer
        zotero # Collect, organize, cite, and share your research sources
        # todoist # Todoist CLI Client
        # todoist-electron # The official Todoist electron app

        # --- SOCIALS ---
        element-desktop # A feature-rich client for Matrix.org
        signal-desktop-bin # Private, simple, and secure messenger
        slack # Desktop client for Slack
        zoom-us # Player for Z-Code, TADS and HUGO stories or games
        # beeper # Universal chat app.
        # spotify # Play music from the Spotify music service
        # vesktop # Alternate client for Discord with Vencord built-in

        # --- DATABASES ---
        mqtt-explorer # An all-round MQTT client that provides a structured topic overview
        mqttui # Terminal client for MQTT
        mqttx # Powerful cross-platform MQTT 5.0 Desktop, CLI, and WebSocket client tools
        pgadmin4-desktopmode # Administration and development platform for PostgreSQL. Desktop Mode
        wireshark # Powerful network protocol analyzer

        # --- MULTIMEDIA ---
        obs-studio # Free and open source software for video recording and live streaming
        mpv # General-purpose media player, fork of MPlayer and mplayer2

        # --- MISC & TOOLS ---
        rpi-imager # Raspberry Pi Imaging Utility
        virt-viewer # Viewer for remote virtual machines
        vscode-fhs # Wrapped variant of vscode which launches in a FHS compatible environment.
        # lapack # openblas with just the LAPACK C and FORTRAN ABI

        # github-desktop # GitHub Desktop
        winbox4 # Graphical configuration utility for RouterOS-based devices
      ];

      programs.winbox.enable = true;
      programs.nix-index-database.comma.enable = true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
