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
  lib,
  pkgs,
  system,
  ...
}:
let
  selfVars = infraVars.hosts.krupikbundle;
  storageBox = infraVars.hosts."storagebundle-1";
  vilaGateway = "192.168.31.1"; # vilekula-nuc, VLAN 31
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

    # backup admin like flatbundle/navibundle (owner's call 2026-10-29): the
    # full-access Storage Box key + repository passwords live here; `backupctl`
    # and the handoff relay use them
    services.backup.restic.admin = {
      enable = true;
      user = "tsandrini";
      repositories = {
        remotebundle = { };
        blehbundle = { };
        pupibundle = { };
      };
      handoff.enable = true;
    };

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
  # ~/.config/handoff/config.toml (private, hand-copied); it logs in with the
  # restic admin key (`key_file` = that agenix secret's path)
  programs.ssh.knownHosts = lib.listToAttrs (
    lib.imap0 (i: key: {
      name = "storagebox-handoff-${toString i}";
      value = {
        hostNames = [ "[${storageBox.address}]:${toString storageBox.port}" ];
        publicKey = key;
      };
    }) ([ pubkeys.hosts."storagebundle-1".hostKey ] ++ pubkeys.hosts."storagebundle-1".extraHostKeys)
  );

  # --- remote console: Sunshine (wlr capture + NVENC + uinput) for Moonlight ---
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

  # --- addressing: static, the DHCP reservation on the vila router is the backup ---
  # NOTE: NetworkManager keeps the Wi-Fi only; the wired NIC is NixOS-managed so
  # the address survives a dead DHCP server and matches what the initrd uses
  networking = {
    networkmanager.unmanaged = [ "enp131s0" ];
    interfaces.enp131s0.ipv4.addresses = [
      {
        inherit (selfVars) address;
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = vilaGateway;
      interface = "enp131s0";
    };
    nameservers = [ vilaGateway ];
  };

  # --- lifelines: the tunnel home must come back by itself, and a box that
  # loses its cable powers off so the disk is locked again ---
  systemd.services.wg-home-tunnel-keepup = {
    description = "Re-establish wg-home-tunnel when it is down";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "wg-home-tunnel-keepup" ''
        if ! ${pkgs.iproute2}/bin/ip link show wg-home-tunnel >/dev/null 2>&1 \
          || ! ${pkgs.systemd}/bin/systemctl is-active --quiet wireguard-wg-home-tunnel.service; then
          echo "wg-home-tunnel is down, restarting"
          ${pkgs.systemd}/bin/systemctl restart wireguard-wg-home-tunnel.service
          ${pkgs.systemd}/bin/systemctl start wireguard-wg-home-tunnel.target
        fi
      '';
    };
  };
  systemd.timers.wg-home-tunnel-keepup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };
  # NOTE: `systemctl stop uplink-deadman` before re-cabling the box on site
  systemd.services.uplink-deadman = {
    description = "Power off when the wired uplink is gone for 60 s";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "uplink-deadman" ''
        iface=enp131s0 limit=60 down=0
        while true; do
          if [ "$(cat /sys/class/net/$iface/carrier 2>/dev/null || echo 0)" = "1" ]; then
            down=0
          else
            down=$((down + 5))
            [ "$down" -eq 5 ] && echo "carrier lost on $iface, powering off in $limit s unless it returns"
            if [ "$down" -ge "$limit" ]; then
              echo "uplink gone for $limit s: powering off"
              ${pkgs.systemd}/bin/systemctl poweroff -i
              exit 0
            fi
          fi
          sleep 5
        done
      '';
    };
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
    # NOTE: stage 1 gets no network config by itself (NetworkManager forces
    # networking.useDHCP = false); this file sorts before the generated
    # 40-enp131s0 and wins the match -- same static address as stage 2
    systemd.network = {
      enable = true;
      networks."10-lan" = {
        matchConfig.Type = "ether";
        address = [ "${selfVars.address}/24" ];
        routes = [ { Gateway = vilaGateway; } ];
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
