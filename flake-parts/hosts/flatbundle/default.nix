# --- flake-parts/hosts/flatbundle/default.nix
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
  pkgs,
  system,
  ...
}:
let
  pkgs-osu-lazer-bin = import inputs.nixpkgs-osu-lazer-bin {
    inherit system;
    config.allowUnfree = true;
  };
  # pkgs-claude-code = import inputs.nixpkgs-claude-code {
  #   inherit system;
  #   config.allowUnfree = true;
  # };
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # Model: Lenovo Thinkpad T14

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
    (inputs.nix-mineral + "/nix-mineral.nix")

    ./hardware-configuration.nix
    # ./nm-overrides.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [
    pkgs.libva-utils # Collection of utilities and examples for VA-API
    pkgs.docker-compose # Docker CLI plugin to define and run multi-container applications with Docker
    # pkgs.python3Packages.playwright # Python version of the Playwright testing and automation library
    # pkgs.playwright # Framework for Web Testing and Automation
    # pkgs.playwright-mcp # Playwright MCP server
    # pkgs.playwright-test # Framework for Web Testing and Automation

    # TODO: electron 39 brokey temporarily
    # pkgs.bitwarden-desktop # Secure and free password manager for all of your devices
    # pkgs.bitwarden-cli # Secure and free password manager for all of your devices
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
    };

    security.agenix.enable = true;

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
  # nix-mineral.enable = true;

  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = [
        # WG
        51820
        51821
        # Dev ports
        8000
        8080
        5173
      ];
      allowedUDPPorts = [
        # WG
        51820
        51821
        # Dev ports
        8000
        8080
        5173
      ];
    };
  };

  programs.nh.flake = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles";
  programs.nh.clean.enable = false; # NOTE We have enough space buddy

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

  # STEAM STUFF
  services.pipewire.lowLatency.enable = true;
  hardware.graphics.enable32Bit = true;
  programs.steam = {
    enable = true;
    platformOptimizations.enable = true;
    extraPackages = [
      pkgs.gamescope
      pkgs.xwayland-run
    ];
  };

  services.xl2tpd.enable = true;
  services.strongswan = {
    enable = true;
    secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  services.tailscale.enable = true;
  networking.wireguard.enable = true;

  home-manager.users."tsandrini" = {
    imports = [
      inputs.mcp-servers-nix.homeManagerModules.default
    ];

    tensorfiles.hm = {
      profiles.graphical-dms-niri.enable = true;
      programs.pywal.enable = true;
      services.pywalfox-native.enable = true;

      profiles.accounts.tsandrini.enable = true;
      security.agenix.enable = true;
      programs.editors.emacs-doom.enable = true;
      services.keepassxc.enable = true;
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
      # everything.enable = true;
      # github.enable = true;
    };

    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      enableMcpIntegration = true;
    };

    home.packages = [
      pkgs-osu-lazer-bin.osu-lazer-bin
      pkgs.olympus
      pkgs.keybase-gui # Keybase official GUI
      pkgs.kbfs # Keybase filesystem

      # --- LLM garbage ---
      inputs.self.packages.${system}.cc-switcher
      # pkgs.llm-agents.claude-code # Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
      pkgs.llm-agents.codex # OpenAI Codex CLI - a coding agent that runs locally on your computer
      pkgs.llm-agents.auto-claude # Autonomous multi-agent coding framework powered by Claude AI
      # pkgs.llm-agents.cc-switch-cli # CLI version of CC Switch - All-in-One Assistant for Claude Code, Codex & Gemini CLI
      pkgs.llm-agents.claude-plugins # CLI tool for managing Claude Code plugins
      pkgs.llm-agents.claudebox # Sandboxed environment for Claude Code
      pkgs.llm-agents.skills-installer # Install agent skills across multiple AI coding clients
      pkgs.llm-agents.sandbox-runtime # Lightweight sandboxing tool for enforcing filesystem and network restrictions
      pkgs.llm-agents.ccusage # Usage analysis tool for Claude Code
      pkgs.llm-agents.agent-browser # Headless browser automation CLI for AI agents
    ];
  };
}
