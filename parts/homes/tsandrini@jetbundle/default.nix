# --- parts/homes/tsandrini@jetbundle/default.nix
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
{
  pkgs,
  inputs',
  ...
}: {
  tensorfiles.hm = {
    profiles.graphical-xmonad.enable = true;
    # enable patches since we arent on NixOS
    hardware.nixGL.programPatches.enable = true;

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
    beeper
    armcord
    anki
    shfmt
    libreoffice
    neofetch
    pavucontrol
    # spotify
    texlive.combined.scheme-medium
    zotero
    lapack

    # TODO these are normally part of the nixos/minimal profile
    htop
    wget
    curl
    jq
    killall
    openssl
    vim
    calcurse
    w3m
    exfat
    dosfstools
    udisks
    pciutils
    iotop
    unrar
    usbutils
    inputs'.nh.packages.default
  ];
}
