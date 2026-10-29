# --- flake-parts/hosts/krupikbundle/default.nix
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
{
  inputs,
  pubkeys,
  infraVars,
  secretsPath,
}:
{
  config,
  pkgs,
  system,
  ...
}:
let
  selfVars = infraVars.hosts.krupikbundle;
  storageBox = infraVars.hosts."storagebundle-1";
  mikrobundleWgPublicKey = "RY2XHIRk+2RtA27EUQdLj+CcqAP2Izj4cGI3Nm0d5CE="; # pragma: allowlist secret
in
{
  # -----------------
  # | SPECIFICATION |
  # -----------------
  # ASUS ROG NUC 15 (NUC15JNKU9X6, Meteopress work box at the vila, 2026-10-26):
  # Core Ultra 9 275HX, 30 GB, RTX 5070 mobile (display outputs) + Arrow Lake
  # iGPU, 2x Kingston KC3000 2 TB NVMe, Killer E3000 2.5GbE, BE200 Wi-Fi 7.
  # Always on, remotely unlocked LUKS; the flatbundle/navibundle workstation
  # minus gaming, photo editing, keybase and the restic admin role.

  # --------------------------
  # | ROLES & MODULES & etc. |
  # --------------------------
  imports = [
    inputs.disko.nixosModules.disko
    inputs.ccdash.nixosModules.default

    ./hardware-configuration.nix
    ./disko.nix
  ];

  # ------------------------------
  # | ADDITIONAL SYSTEM PACKAGES |
  # ------------------------------
  environment.systemPackages = [
    pkgs.libva-utils # Collection of utilities and examples for VA-API
    pkgs.docker-compose # Docker CLI plugin to define and run multi-container applications
    pkgs.tigervnc # Fork of tightVNC, made in cooperation with VirtualGL
    pkgs.screen # Window manager that multiplexes a physical terminal
    pkgs.picocom # Minimal dumb-terminal emulation program
    pkgs.cameractrls-gtk4 # Camera controls for Linux

    # --- box hardware ---
    pkgs.lm_sensors # Tools for reading hardware sensors
    pkgs.smartmontools # Tools for monitoring the health of hard drives
    pkgs.nvme-cli # NVM-Express user space tooling for Linux
    pkgs.vulkan-tools # Khronos official Vulkan Tools and Utilities
    pkgs.nvtopPackages.nvidia # (h)top like task monitor for NVIDIA GPUs
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

      # NOTE: deploy/kexec target from the laptop, same posture as navibundle:
      # key-only sshd (port 2222, root login off) + `deploy` sudo user
      with-deploy-user.enable = true;
    };
    services.networking.ssh.enable = true;
    networking.ssh-aliases.enable = true;
    security.hardening.desktop.enable = true;

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
        "uinput" # NOTE: required for Sunshine's input injection (/dev/uinput)
        "docker"
        "dialout"
      ];
    };
  };

  services.openssh.openFirewall = false;
  # NOTE: the fleet-wide sshd turns TCP forwarding off (no pivoting through a
  # host); this box's own user needs `ssh -L` for VNC and dev servers
  services.openssh.extraConfig = ''
    Match User tsandrini
      AllowTcpForwarding yes
  '';
  tensorfiles.networking.firewall.subnets-firewall = {
    nixosPassthrough = {
      allowedTCPPorts = [
        #
      ];
    };
    defaultSubnets = {
      allowedTCPPorts = config.services.openssh.ports ++ [
        # WG
        51820
        51821
        # Dev ports
        8000
        8080
        8081
        5173
        # android wireless ADB
        43669
      ];
      allowedUDPPorts = [
        # WG
        51820
        51821
        # Dev ports
        8000
        8080
        8081
        5173
        # android wireless ADB
        43669
      ];
    };
  };
  # sshd from home over tailscale; nothing else is reachable through the tunnel
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports;

  # --- home network: WireGuard peer on mikrobundle ---
  # NOTE: same shape as blehbundle. The tunnel carries the home LAN and the
  # road-warrior subnet only; what this peer may actually reach is decided by
  # mikrobundle's firewall (ccdash hub + DNS on pupibundle), not here.
  networking.wireguard.interfaces.wg-home-tunnel = {
    ips = [ "${selfVars.wgAddress}/32" ];
    privateKeyFile = config.age.secrets."hosts/krupikbundle/wg-home-tunnel-privkey".path;
    peers = [
      {
        publicKey = mikrobundleWgPublicKey;
        # NOTE: home LAN + road-warrior subnet only. Never the firewall
        # allowlist: it holds the vila subnets this box *sits in*, and every
        # allowed IP becomes a route -- LAN replies would leave via the tunnel
        allowedIPs = [
          infraVars.common.networking.defaultSubnet
          infraVars.common.networking.intranetSubnet
        ];
        # NOTE: endpoint is owned by wireguard-endpoint-watchdog below
        persistentKeepalive = 25;
      }
    ];
    # split DNS: only *.home names go to Pi-hole through the tunnel, the rest
    # stays on the vila's resolver (and survives the tunnel being down)
    postSetup = ''
      ${pkgs.systemd}/bin/resolvectl dns wg-home-tunnel ${infraVars.hosts.pupibundle.address}
      ${pkgs.systemd}/bin/resolvectl domain wg-home-tunnel '~home.tsandrini.sh'
    '';
  };
  services.resolved.enable = true;
  tensorfiles.networking.wireguard-endpoint-watchdog = {
    enable = true;
    interfaces.wg-home-tunnel = {
      peerPublicKey = mikrobundleWgPublicKey;
      endpointHost = "vpn.tsandrini.sh";
      endpointPort = 51821;
    };
  };
  age.secrets."hosts/krupikbundle/wg-home-tunnel-privkey".file =
    "${secretsPath}/hosts/krupikbundle/wg-home-tunnel-privkey.age";

  # handoff's sftp relay (rclone) pins the Storage Box here, see
  # ~/.config/handoff/config.toml (private, hand-copied); the box logs in as
  # a Hetzner sub-account whose home *is* the relay, so its key sees no backups
  programs.ssh.knownHosts."storagebox-handoff" = {
    hostNames = [ "[${storageBox.address}]:${toString storageBox.port}" ];
    publicKey = pubkeys.hosts."storagebundle-1".hostKey;
  };

  # --- remote console: Sunshine (wlr capture + NVENC + uinput) for Moonlight ---
  # NOTE: niri runs no compositor binds on virtual-keyboard input (wayvnc), so
  # the usable remote desktop is Sunshine: input arrives as real uinput
  # devices. Capture is niri's screencopy ("wlr"): the portal probe hangs
  # (no ScreenCast backend) and KMS finds no monitors on the NVIDIA card. The
  # frames live on the dGPU, so only NVENC (CUDA build) or software can encode
  # them -- VA-API sits on the iGPU. Reachable over the home tunnel only; pair +
  # web UI at https://<wgAddress>:47990. mDNS stays off (office LAN).
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false;
    openFirewall = false;
    package = pkgs.sunshine.override { cudaSupport = true; };
    settings = {
      capture = "wlr";
      # the web UI is reached by its tunnel address, not localhost
      csrf_allowed_origins = "https://${selfVars.wgAddress}:47990";
    };
    # NOTE: the office screens must not stay on an open session once the
    # stream ends -> lock DMS on disconnect. Keeping them dark *during* a
    # stream needs disabled outputs plus an invisible one to capture (dummy
    # plug on the dGPU); DPMS alone wakes on the very input Sunshine injects.
    applications.apps = [
      {
        name = "Desktop";
        image-path = "desktop.png";
        prep-cmd = [
          {
            do = "";
            undo = "/etc/profiles/per-user/tsandrini/bin/dms ipc call lock lock";
          }
        ];
      }
    ];
  };
  services.avahi.enable = false;
  networking.firewall.interfaces.wg-home-tunnel = {
    allowedTCPPortRanges = [
      {
        from = 47984;
        to = 47990;
      }
    ];
    allowedTCPPorts = [ 48010 ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48010;
      }
    ];
  };

  # --- boot chain: LUKS unlock from home ---
  boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2223;
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = pubkeys.hosts.krupikbundle.users.tsandrini.authorizedKeys;
      };
    };
    systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    # NOTE: NetworkManager forces networking.useDHCP = false, so stage 1 gets no
    # DHCP by itself (the wakeOnLan interface even yields a 40-enp131s0 with
    # DHCP=no); this file sorts first and wins the match
    systemd.network = {
      enable = true;
      networks."10-lan" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "ipv4";
        # same client-id as NetworkManager -> same lease in stage 1 and 2
        dhcpV4Config.ClientIdentifier = "mac";
      };
    };
  };

  # --- always on ---
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
  # Intel PCH watchdog (iTCO): a hung box resets itself, nobody is at the vila
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  # NOTE: lets the HM `claude` wrapper load the ccdash channel without the
  # dev-channel dialog (replaces Anthropic's default channel allowlist)
  programs.ccdash.channel.allow = true;

  programs.nh.flake = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles";
  programs.nh.clean.enable = false;

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.bash;

  programs.bash = {
    interactiveShellInit = ''
      # NOTE -z IN_NIX_SHELL: nix-shell/nix develop set up their env in the rcfile
      # sourced *after* this file; exec'ing fish here would skip it
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} && -z ''${IN_NIX_SHELL} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

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
  services.fwupd.enable = true;

  # NOTE: pinned so the install can deliver the dedicated user key with the
  # right owner (`nixos-anywhere --chown /home/tsandrini/.ssh 1001:100`, see
  # disko.nix); tmpfiles cannot fix it afterwards ("unsafe path transition"
  # into a root-owned dir under the user's home) and NixOS allocates uids
  # alphabetically, so deploy would otherwise float
  users.users.deploy.uid = 1000;
  users.users.tsandrini.uid = 1001;

  home-manager.users."tsandrini" = {
    imports = [
      inputs.mcp-servers-nix.homeManagerModules.default
    ];

    tensorfiles.hm = {
      programs.handoff.enable = true;
      programs.dank-calendar.enable = true;
      profiles.graphical-dms-niri.enable = true;
      programs.pywal.enable = true;
      services.pywalfox-native.enable = true;

      profiles.accounts.tsandrini.enable = true;
      security.agenix.enable = true;
      programs.editors.emacs-doom.enable = true;
      services.keepassxc.enable = true;
      services.ccdash.enable = true;

      programs.claude-code = {
        enable = true;
        homeAssistant.enable = true;
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
      pkgs.teams-for-linux # Unofficial Microsoft Teams client for Linux
      pkgs.drawio # Desktop version of draw.io for creating diagrams
      pkgs.bitwarden-desktop
      pkgs.google-clasp # Develop Apps Script Projects locally

      # --- LLM garbage ---
      # NOTE: claude-code ecosystem CLIs come from tensorfiles.hm.programs.claude-code (extraPackages)
      inputs.llm-agents.packages.${system}.codex # OpenAI Codex CLI
    ];
  };
}
