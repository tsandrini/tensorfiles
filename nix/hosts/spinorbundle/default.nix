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

{ config, pkgs, inputs, user, lib, ... }:

{
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
  environment.systemPackages = with pkgs; [
    snapper
    htop
    git
    killall
    pciutils
    usbutils
    wget
    vim
  ];

  system.stateVersion = "23.05";
  home-manager.users.${user} =  {
    home.stateVersion = "23.05";
  };

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.timeout = 1;
  boot.loader.grub.enable = false;


  # Services
  # services.tlp.enable = true;
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };


  # services.xserver = {
  #   enable = true;
  #   libinput.enable = true;
  #   videoDrivers = [ "intel" ];
  #   windowManager.xmonad = {
  #     enable = true;
  #     enableContribAndExtras = true;
  #   };
  #   displayManager.defaultSession = "none+xmonad";
  #   displayManager.lightdm = {
  #     enable = true;
  #     # greeters.slick = {
  #     #   enable = true;
  #     # };
  #     # extraConfig = ''
  #     #   greeter-user=${user}
  #     # '';
  #   };
  # };

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

  services.xserver = {
    enable = true;
    windowManager = {
      # default = "xmonad";
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };
    # On nixos-unstable I needed to add this deprecated setting (not sure if still needed)
    # desktopManager.default = "none";
    displayManager.defaultSession = "none+xmonad";
  };

  networking.networkmanager.enable = true;

  programs.ssh.startAgent = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  time.timeZone = "Europe/Prague";

  i18n.defaultLocale = "en_US.UTF-8";

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
    allowReboot = true;
    rebootWindow = {
      lower = "02:00";
      upper = "05:00";
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
    package = pkgs.nixVersions.unstable;
    registry.nixpkgs.flake = inputs.nixpkgs;
    settings.auto-optimise-store = true;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };

  # The whole section below handles opt-in state for /
  # which was inspired by the following blog post
  # https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
  # ---------------------------------------------------
  environment.etc = {
    passwd.source = "/persist/etc/passwd"; # TODO temporary, moving to agenix
    shadow.source = "/persist/etc/shadow"; # TODO
    nixos.source = "/persist/etc/tensorfiles/nix"; # TODO the nix folder will be removed
    adjtime.source = "/persist/etc/adjtime";
    machine-id.source = "/persist/etc/machine-id";
    "NetworkManager/system-connections".source = "/persist/etc/NetworkManager/system-connections";
  };

  systemd.tmpfiles.rules = [
    "L /var/lib/NetworkManager/secret_key - - - - /persist/var/lib/NetworkManager/secret_key"
    "L /var/lib/NetworkManager/seen-bssids - - - - /persist/var/lib/NetworkManager/seen-bssids"
    "L /var/lib/NetworkManager/timestamps - - - - /persist/var/lib/NetworkManager/timestamps"
  ];

  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  # Note `lib.mkBefore` is used instead of `lib.mkAfter` here.
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt

    # We first mount the btrfs root to /mnt
    # so we can manipulate btrfs subvolumes.
    mount -o subvol=/ /dev/mapper/enc /mnt

    # While we're tempted to just delete /root and create
    # a new snapshot from /root-blank, /root is already
    # populated at this point with a number of subvolumes,
    # which makes `btrfs subvolume delete` fail.
    # So, we remove them first.
    #
    # /root contains subvolumes:
    # - /root/var/lib/portables
    # - /root/var/lib/machines
    #
    # I suspect these are related to systemd-nspawn, but
    # since I don't use it I'm not 100% sure.
    # Anyhow, deleting these subvolumes hasn't resulted
    # in any issues so far, except for fairly
    # benign-looking errors from systemd-tmpfiles.
    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
      echo "deleting /$subvolume subvolume..."
      btrfs subvolume delete "/mnt/$subvolume"
    done &&
    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/root-blank /mnt/root

    # Once we're done rolling back to a blank snapshot,
    # we can unmount /mnt and continue on the boot process.
    umount /mnt
  '';
}
