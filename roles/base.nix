# --- roles/base.nix
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
{ inputs, user, ... }: {
  # TODO will decouple when I'll have most of the stuff done
  imports = with inputs.self; [
    # --------------------
    # | EXTERNAL MODULES |
    # --------------------
    # { system.stateVersion = "23.05"; }
    # inputs.home-manager.nixosModules.home-manager
    # inputs.impermanence.nixosModules.impermanence
    # inputs.agenix.nixosModules.default
    # inputs.nur.nixosModules.nur

    # -----------
    # | MODULES |
    # -----------
    # nixosModules.hello

    # ------------
    # | PROFILES |
    # ------------
    # nixosProfiles.agenix
    # nixosProfiles.tty
    # nixosProfiles.system-maintenance
    # nixosProfiles.system-packages
    # nixosProfiles.persist-btrfs
    # nixosProfiles.localization
    # nixosProfiles.networking-nm
    nixosProfiles.xmonad-with-xmobar-pywaled
    # nixosProfiles.home-manager
    # nixosProfiles.home-xdg
    # nixosProfiles.home-git
    # nixosProfiles.home-zsh
    nixosProfiles.home-neovim
    nixosProfiles.home-pywal
    nixosProfiles.home-pywalfox-native
    nixosProfiles.home-picom
    nixosProfiles.home-alacritty
    nixosProfiles.home-newsboat
    nixosProfiles.home-lf
    nixosProfiles.home-dmenu-pywaled
    nixosProfiles.home-redshift
    nixosProfiles.home-dunst-pywaled
    nixosProfiles.home-gtk
    nixosProfiles.home-firefox
  ];
}