# --- parts/hosts/jetbundle/default.nix
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
  inputs,
  ...
}: {
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo B51-80

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
    ./hardware-configuration.nix
    ./disko.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [libva-utils];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  # home-manager.users.${user} = {home.packages = with pkgs; [];};

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  tensorfiles = {
    profiles.graphical-plasma.enable = true;

    security.agenix.enable = true;
    programs.shadow-nix.enable = true;
    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
    };
  };

  programs.shadow-client.forceDriver = "iHD";
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  programs.steam.enable = true; # just trying it out

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  home-manager.users."tsandrini" = {
    tensorfiles.hm = {
      profiles.graphical-plasma.enable = true;
      security.agenix.enable = true;

      programs.pywal.enable = true;
      programs.spicetify.enable = true;
      services.pywalfox-native.enable = true;
      services.keepassxc.enable = true;
    };

    # TODO remove
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = false;

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
      thunderbird
      beeper
      armcord
      anki
      shfmt
      libreoffice
      neofetch
      texlive.combined.scheme-medium
      zotero
      lapack

      slack
      signal-desktop
    ];
  };
}
