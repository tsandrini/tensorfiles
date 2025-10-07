# --- flake-parts/hosts/spinorbundle/default.nix
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
{ inputs }:
{ pkgs, system, ... }:
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo B51-80

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.nix-index-database.nixosModules.nix-index
    (inputs.nix-mineral + "/nix-mineral.nix")

    # TODO fails with The option `programs.steam.extraCompatPackages' in
    # `/nix/store/nra828scc8qs92b9pxra5csqzffb6hpl-source/nixos/modules/programs/steam.nix'
    # is already declared in
    # `/nix/store/cqapfi5bvhzvarrbi2h1qrf2dav5r1nd-source/flake.nix#nixosModules.steamCompat'.
    # nix-gaming.nixosModules.steamCompat
    ./hardware-configuration.nix
    ./disko.nix
    ./nm-overrides.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [
    networkmanagerapplet # need this to configure L2TP ipsec
  ];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  # home-manager.users.${user} = {home.packages = with pkgs; [];};

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  tensorfiles = {
    profiles = {
      graphical-plasma6.enable = true;
      packages-base.enable = true;
      packages-extra.enable = true;
      # packages-graphical-extra.enable = true;
    };

    security.agenix.enable = true;
    # programs.shadow-nix.enable = true;
    tasks.system-autoupgrade.enable = false;

    system.users.usersSettings."root" = {
      agenixPassword.enable = true;
    };
    system.users.usersSettings."tsandrini" = {
      isSudoer = true;
      isNixTrusted = true;
      agenixPassword.enable = true;
      extraGroups = [
        "video"
        "camera"
        "audio"
        "networkmanager"
        "input"
        "docker"
      ];
    };
  };
  # nix-mineral.enable = true;

  # Use the `nh` garbage collect to also collect .direnv and XDG profiles
  # roots instead of the default ones.
  tensorfiles.tasks.nix-garbage-collect.enable = false;
  tensorfiles.programs.nh.enable = true;
  # TODO maybe use github:tsandrini/tensorfiles instead?
  programs.nh.flake = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles";

  # programs.shadow-client.forceDriver = "iHD";
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.bash;

  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.steam = {
    enable = true;
    # extest.enable = true;
    platformOptimizations.enable = true;
    extraPackages = with pkgs; [
      gamescope
      xwayland-run
    ];
  };
  hardware.graphics.enable32Bit = true;

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      lowLatency.enable = true;
    };
  };

  services.openssh.enable = false;
  services.fail2ban.enable = false;

  networking.networkmanager.enable = true;

  services.pcscd.enable = true; # # Needed for gpg pinetry
  #
  # virtualisation.docker = {
  #   enable = true;
  #   autoPrune.enable = true;
  #   storageDriver = "btrfs";
  # };

  # NOTE for wireguard
  # networking.wireguard.enable = true;
  networking.firewall = {
    allowedUDPPorts = [
      51820
      8000
      8080
      5173
    ];
    allowedTCPPorts = [
      8000
      8080
      5173
    ];
  };

  # If you intend to route all your traffic through the wireguard tunnel, the
  # default configuration of the NixOS firewall will block the traffic because
  # of rpfilter. You can either disable rpfilter altogether:
  # networking.firewall.checkReversePath = false;

  home-manager.users."tsandrini" = {
    tensorfiles.hm = {
      profiles.graphical-plasma.enable = true;
      security.agenix.enable = true;

      programs.pywal.enable = true;
      # programs.spicetify.enable = true;
      # services.pywalfox-native.enable = true;
      services.keepassxc.enable = true;
      # services.activitywatch.enable = true;
    };

    services.syncthing = {
      enable = true;
      tray.enable = true;
    };

    home.username = "tsandrini";
    home.homeDirectory = "/home/tsandrini";
    home.sessionVariables = {
      DEFAULT_USERNAME = "tsandrini";
      DEFAULT_MAIL = "t@tsandrini.sh";
    };
    programs.git.signing.key = "3E83AD690FA4F657"; # pragma: allowlist secret

    home.packages = [
      #
    ];
  };
}
