# --- hosts/home.nix
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

{ config, lib, pkgs, user, ... }:

{
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    packages = with pkgs; [
      htop
      btop

      rsync
      unzip
      unrar

      neovim
    ];
    stateVersion = "23.05";
  };

  programs = {
   home-manager.enable = true;
  };

  # gtk = {                                     # Theming
  #   enable = true;
  #   theme = {
  #     name = "Dracula";
  #     #name = "Catppuccin-Dark";
  #     package = pkgs.dracula-theme;
  #     #package = pkgs.catppuccin-gtk;
  #   };
  #   iconTheme = {
  #     name = "Papirus-Dark";
  #     package = pkgs.papirus-icon-theme;
  #   };
  #   font = {
  #     name = "JetBrains Mono Medium";         # or FiraCode Nerd Font Mono Medium
  #   };                                        # Cursor is declared under home.pointerCursor
  # };
}
