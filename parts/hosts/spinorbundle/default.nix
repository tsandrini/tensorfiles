# --- parts/hosts/spinorbundle/default.nix
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
{pkgs, ...}: {
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo B51-80

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [./hardware-configuration.nix];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  # environment.systemPackages = with pkgs; [];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  # home-manager.users.${user} = {home.packages = with pkgs; [];};

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  tensorfiles = {
    profiles.graphical-startx-home-manager.enable = true;
    # TODO
    # services.networking.openssh.genHostKey.enable = false;
    # services.networking.openssh.agenix.hostKey.enable = false;

    security.agenix.enable = true;
    system.impermanence = {
      enable = true;
      allowOther = true;
      btrfsWipe = {
        enable = true;
        rootPartition = "/dev/mapper/enc";
      };
    };
    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
    };
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  home-manager.users."tsandrini" = {
    tensorfiles.hm = {
      profiles.graphical-xmonad.enable = true;

      system.impermanence = {
        enable = true;
        allowOther = true;
      };

      security.agenix.enable = true;

      programs.pywal.enable = true;
      services.pywalfox-native.enable = true;
      services.keepassxc.enable = true;
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
      spotify
      texlive.combined.scheme-medium
      zotero
      lapack
    ];
  };

  boot = {
    loader = {
      timeout = 1;
      grub.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
    };
    binfmt.emulatedSystems = ["aarch64-linux"];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;

    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    bluetooth = {
      enable = true;
      package = pkgs.bluez;
    };
  };

  services = {
    blueman.enable = true;
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT1 = 75;
        STOP_CHARGE_THRESH_BAT1 = 80;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  programs.steam.enable = true; # just trying it out
}
