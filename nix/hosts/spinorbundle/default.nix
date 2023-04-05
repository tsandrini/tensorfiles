# --- hosts/spinorbundle/default.nix
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
{ config, pkgs, inputs, user, lib, system, ... }: {
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo B51-80

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = with inputs.self; [
    ./hardware-configuration.nix
    nixosRoles.laptop
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [ ];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  home-manager.users.${user} = { home.packages = with pkgs; [ ]; };

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.timeout = 1;
  boot.loader.grub.enable = false;

  # Services
  services.tlp.enable = true;
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  programs.ssh.startAgent = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.home-assistant = {
    enable = true;
    port = 8123;
    extraComponents = [
      "met"
      "radio_browser"
    ];
    config = {
      default_config = {};
      frontend = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
  };

  users.users.${user}.passwordFile =
    config.age.secrets."hosts/spinorbundle/passwords/users/${user}".path;

  users.users.root.passwordFile =
    config.age.secrets."hosts/spinorbundle/passwords/users/root".path;

  age.secrets."hosts/spinorbundle/passwords/users/${user}".file =
    ../../secrets/hosts/spinorbundle/passwords/users/${user}.age;
  age.secrets."hosts/spinorbundle/passwords/users/root".file =
    ../../secrets/hosts/spinorbundle/passwords/users/root.age;
}
