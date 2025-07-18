# --- flake-parts/hosts/jetbundle/default.nix
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
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
    inputs.nix-index-database.nixosModules.nix-index
    # Fingerprint sensor
    # nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
    # nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
    (inputs.nix-mineral + "/nix-mineral.nix")

    ./disko.nix
    ./hardware-configuration.nix
    ./nm-overrides.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = with pkgs; [
    libva-utils
    networkmanagerapplet # need this to configure L2TP ipsec
    docker-compose
    wireguard-tools
  ];

  # ----------------------------
  # | ADDITIONAL USER PACKAGES |
  # ----------------------------
  # home-manager.users.${user} = {home.packages = with pkgs; [];};

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  tensorfiles = {
    profiles.graphical-plasma6.enable = true;
    profiles.packages-base.enable = true;
    profiles.packages-extra.enable = true;

    security.agenix.enable = true;
    programs.shadow-nix.enable = false;

    # Use the `nh` garbage collect to also collect .direnv and XDG profiles
    # roots instead of the default ones.
    tasks.nix-garbage-collect.enable = false;
    programs.nh.enable = true;

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
  nix-mineral.enable = true;

  # TODO maybe use github:tsandrini/tensorfiles instead?
  programs.nh.flake = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles";

  programs.shadow-client.forceDriver = "iHD";
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

  programs.winbox.enable = true;
  programs.nix-index-database.comma.enable = true;

  # services.udev.packages = with pkgs; [
  #   via
  #   vial
  # ];

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  networking.networkmanager.enableStrongSwan = true;
  services.xl2tpd.enable = true;
  services.strongswan = {
    enable = true;
    secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
  };

  # Needed for gpg pinetry
  services.pcscd.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "btrfs";
  };

  # NOTE for wireguard
  networking.wireguard.enable = true;
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
  networking.firewall.checkReversePath = false;

  home-manager.users."tsandrini" = {
    tensorfiles.hm = {

      profiles.graphical-plasma.enable = true;
      profiles.accounts.tsandrini.enable = true;
      security.agenix.enable = true;

      programs.pywal.enable = true;
      # programs.spicetify.enable = true;
      # services.pywalfox-native.enable = true;
      programs.editors.emacs-doom.enable = true;
      services.keepassxc.enable = true;
      services.activitywatch.enable = true;
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

    home.packages = with pkgs; [
      # thunderbird # A full-featured e-mail client
      # beeper # Universal chat app.
      anki # Spaced repetition flashcard program
      libreoffice # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
      texlive.combined.scheme-full # TeX Live environment
      zotero # Collect, organize, cite, and share your research sources
      lapack # openblas with just the LAPACK C and FORTRAN ABI
      ungoogled-chromium # An open source web browser from Google, with dependencies on Google web services removed
      zoom-us # Player for Z-Code, TADS and HUGO stories or games
      vesktop # Alternate client for Discord with Vencord built-in
      gnucash # Free software for double entry accounting

      element-desktop # A feature-rich client for Matrix.org
      slack # Desktop client for Slack
      signal-desktop-bin # Private, simple, and secure messenger
      # github-desktop # GitHub Desktop
      obsidian # A knowledge base that works on top of a local folder of plain text Markdown files
      virt-viewer # Viewer for remote virtual machines

      vscode-fhs # Wrapped variant of vscode which launches in a FHS compatible environment.

      # todoist # Todoist CLI Client
      # todoist-electron # The official Todoist electron app

      wireshark # Powerful network protocol analyzer
      pgadmin4-desktopmode # Administration and development platform for PostgreSQL. Desktop Mode
      mqttui # Terminal client for MQTT
      mqttx # Powerful cross-platform MQTT 5.0 Desktop, CLI, and WebSocket client tools
      mqtt-explorer # An all-round MQTT client that provides a structured topic overview

      spotify # Play music from the Spotify music service
      mpv # General-purpose media player, fork of MPlayer and mplayer2
      zathura # A highly customizable and functional PDF viewer

      # inputs.nix-gaming.packages.${system}.osu-lazer-bin
      # inputs.self.packages.${system}.pywalfox-native
    ];
  };
}
