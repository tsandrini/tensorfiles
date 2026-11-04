# --- flake-parts/hosts/krupikbundle/hardware-configuration.nix
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
#
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;

  # Killer E3000 2.5GbE (Realtek, r8169): magic packet only -- link-change /
  # broadcast wake (`p u b m`) powers a box back on right after shutdown
  networking.interfaces.enp131s0.wakeOnLan = {
    enable = true;
    policy = [ "magic" ];
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
        configurationLimit = 10;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
        # NOTE: required for the initrd sshd (remote LUKS unlock, see default.nix)
        "r8169"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    # NOTE: VT-d DMA remapping behind the Thunderbolt 4 ports (boltd's
    # iommu_dma_protection); the firmware has VT-d on, this keeps the kernel side on
    kernelParams = [ "intel_iommu=on" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    # Arrow Lake iGPU (xe): VA-API for video decode; the dGPU does the rendering
    graphics.extraPackages = [ pkgs.intel-media-driver ];
    # RTX 5070 mobile (GB206, Blackwell) owns the display outputs and is the
    # boot VGA; this GPU generation runs on the open kernel module only
    nvidia = {
      open = true;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      powerManagement.enable = false;
      nvidiaSettings = false;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # The 8 GiB dGPU never spills to RAM and a full one crashes its clients:
  # warn while there is still room to close things
  systemd.user.services.vram-watch = {
    description = "Warn when the dGPU runs low on VRAM";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
        pkgs.writeShellApplication {
          name = "vram-watch";
          runtimeInputs = [
            pkgs.nvtopPackages.nvidia
            pkgs.jq
            pkgs.libnotify
            pkgs.coreutils
          ];
          text = ''
            low_mib=''${VRAM_WATCH_LOW_MIB:-1024}
            state=''${XDG_RUNTIME_DIR:-/tmp}/vram-watch.last

            # at most one toast per 30 min
            warn() {
              local now last
              now=$(date +%s)
              last=$(cat "$state" 2>/dev/null || echo 0)
              if ((now - last >= 1800)); then
                notify-send -u critical -a "VRAM watch" -i dialog-warning "$1" "$2"
                echo "$now" >"$state"
              fi
              echo "$1: $2"
            }

            snap=$(nvtop -s 2>/dev/null) || true
            if ! jq -e '.[0].mem_total | tonumber' >/dev/null 2>&1 <<<"$snap"; then
              warn "VRAM watch cannot read the GPU" "nvtop -s gave no GPU data: ''${snap:0:200}"
              exit 1
            fi

            # NOTE: a pid can be listed as graphic and compute with the same total
            read -r used total owned top < <(jq -r '.[0]
              | ([.processes[]? | {
                  name: (.cmdline | split(" ")[0] | split("/")[-1] | sub("^\\.(?<n>.+)-wrapped_?$"; "\(.n)")),
                  pid,
                  mib: ((.gpu_mem_bytes_alloc // "0") | tonumber / 1048576 | floor)
                }]
                | group_by(.pid) | map(max_by(.mib)) | sort_by(-.mib)) as $procs
              | [ (.mem_used | tonumber / 1048576 | floor),
                  (.mem_total | tonumber / 1048576 | floor),
                  ($procs | map(.mib) | add // 0),
                  ($procs[:3] | map("\(.name) \(.mib) MiB") | join(", ")) ]
              | @tsv' <<<"$snap")

            free=$((total - used))
            if ((free >= low_mib)); then
              exit 0
            fi
            warn "Low VRAM: $free MiB free of $total MiB" \
              "Not owned by any process: $((used - owned)) MiB (leaked buffers?). Top: $top"
          '';
        }
      }/bin/vram-watch";
    };
  };
  systemd.user.timers.vram-watch = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    timerConfig = {
      OnActiveSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };

  # 8 GiB swapfile on the LUKS-backed root (no hibernation: the box never sleeps)
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];
}
