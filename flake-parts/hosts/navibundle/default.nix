# --- flake-parts/hosts/navibundle/default.nix
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
{
  config,
  pkgs,
  system,
  ...
}:
let
  pkgs-osu-lazer-bin = import inputs.nixpkgs-osu-lazer-bin {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Desktop (built 2026-10-05): Ryzen 9 9950X3D, 64 GB DDR5-6400, RX 9070 XT,
  # Gigabyte X870E Aorus Pro X3D Ice, Kingston Renegade G5 2 TB NVMe,
  # Fractal Define 7. UX mirrors flatbundle (niri + DMS), hardware bindings
  # differ. Validation notes: ProjectBundle/desktop-build/02-hardware-validation-*.md

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.disko.nixosModules.disko
    # inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations

    ./hardware-configuration.nix
    ./disko.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [
    pkgs.libva-utils # Collection of utilities and examples for VA-API
    pkgs.docker-compose # Docker CLI plugin to define and run multi-container applications
    pkgs.screen # Window manager that multiplexes a physical terminal
    pkgs.picocom # Minimal dumb-terminal emulation program

    # --- desktop hardware ---
    pkgs.lm_sensors # Tools for reading hardware sensors
    pkgs.smartmontools # Tools for monitoring the health of hard drives
    pkgs.nvme-cli # NVM-Express user space tooling for Linux
    pkgs.vulkan-tools # Khronos official Vulkan Tools and Utilities
    pkgs.radeontop # Top-like tool for viewing AMD Radeon GPU utilization
    pkgs.nvtopPackages.amd # (h)top like task monitor for AMD GPUs
  ];

  # ---------------------
  # | ADDITIONAL CONFIG |
  # ---------------------
  tensorfiles = {
    profiles = {
      graphical-dms-niri.enable = true;

      packages-base.enable = true;
      packages-extra.enable = true;
      packages-graphical-extra.enable = true;

      # NOTE: unlike flatbundle this box is a deploy/kexec target from the
      # laptop: key-only sshd (port 2222, root login off) + `deploy` sudo user,
      # reachable from the LAN subnets only (see subnets-firewall below)
      with-deploy-user.enable = true;
    };
    services.networking.ssh.enable = true;
    security.hardening.desktop.enable = true;
    # NOTE: required for optical media (external DVD drive, retrowine dumps)
    security.hardening.base.allowedKernelModules = [ "udf" ];

    security.agenix.enable = true;

    # NOTE: no remote-builders client here -- binfmt aarch64 on 16 Zen 5 cores
    # beats building on the Pi, and it would need hosts/navibundle/nix-remote-builder-ssh-key

    tasks.nix-garbage-collect.enable = false;
    programs.nh.enable = true;

    programs.retrowine = {
      enable = true;
      root = "/mnt/hdd-backup/games-backup";
    };

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
        "dialout"
        "cdrom" # NOTE: required for cdemu (/dev/vhba_ctl)
      ];
    };
  };

  services.openssh.openFirewall = false;
  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = config.services.openssh.ports ++ [
        51820
        51821
        8000
        8080
        8081
        5173
        43669
      ];
      allowedUDPPorts = [
        51820
        51821
        8000
        8080
        8081
        5173
        43669
      ];
    };
  };

  programs.nh.flake = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles";
  programs.nh.clean.enable = false; # NOTE We have enough space buddy

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.bash;

  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} && -z ''${IN_NIX_SHELL} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # --- graphics & gaming ---
  hardware.graphics.enable32Bit = true;
  programs.steam = {
    enable = true;
    platformOptimizations.enable = true;
    extraPackages = [
      pkgs.gamescope
      pkgs.xwayland-run
    ];
  };
  # services.pipewire.lowLatency.enable = true;
  # GPU clocks/fans/power curves without root (RX 9070 XT)
  services.lact.enable = true;

  # --- board hardware ---
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  services.tailscale.enable = true;
  networking.wireguard.enable = true;

  services.udev.packages = [
    pkgs.qmk
    pkgs.qmk-udev-rules
    pkgs.qmk_hid
    pkgs.via
    pkgs.vial
  ];

  services.envfs.enable = true;
  services.fstrim.enable = true;

  home-manager.users."tsandrini" = {
    imports = [
      inputs.mcp-servers-nix.homeManagerModules.default
    ];

    tensorfiles.hm = {
      programs.handoff.enable = true;
      profiles.graphical-dms-niri.enable = true;
      # Philips 346B1C ultrawide; the vertical Dell is HDMI-A-1
      programs.niri-flake.workspaces.output = "DP-1";
      programs.pywal.enable = true;
      services.pywalfox-native.enable = true;

      profiles.accounts.tsandrini.enable = true;
      security.agenix.enable = true;
      programs.editors.emacs-doom.enable = true;
      services.keepassxc.enable = true;

      programs.claude-code = {
        enable = true;
        mikrotikLookup.enable = true;
      };
    };

    services.syncthing = {
      enable = true;
      tray.enable = true;
    };

    home.sessionVariables = {
      DEFAULT_USERNAME = "tsandrini";
      DEFAULT_MAIL = "t@tsandrini.sh";
    };
    programs.git.signing.key = "3E83AD690FA4F657"; # pragma: allowlist secret

    programs.mcp.enable = true;

    mcp-servers.programs = {
      playwright.enable = true;
      playwright.args = [ "--headless" ];
      nixos.enable = true;
      time.enable = true;
      fetch.enable = true;
    };

    programs.ssh.includes = [
      "${inputs.meteopress-radar-radar_deploy}/ssh/radars"
      "${inputs.meteopress-radar-radar_deploy}/ssh/dev"
      "${inputs.meteopress-radar-radar_deploy}/ssh/vilekula"
    ];

    home.packages = [
      pkgs-osu-lazer-bin.osu-lazer-bin
      pkgs.olympus
      pkgs.keybase-gui # Keybase official GUI
      pkgs.kbfs # Keybase filesystem
      pkgs.teams-for-linux # Unofficial Microsoft Teams client for Linux
      pkgs.prismlauncher # Free, open source launcher for Minecraft
      pkgs.drawio # Desktop version of draw.io for creating diagrams
      pkgs.bitwarden-desktop
      pkgs.darktable # Virtual lighttable and darkroom for photographers
      pkgs.rawtherapee # RAW converter and digital photo processing software
      pkgs.google-clasp # Develop Apps Script Projects locally

      # --- LLM garbage ---
      # NOTE: claude-code ecosystem CLIs come from tensorfiles.hm.programs.claude-code (extraPackages)
      inputs.llm-agents.packages.${system}.codex # OpenAI Codex CLI
    ];
  };
}
