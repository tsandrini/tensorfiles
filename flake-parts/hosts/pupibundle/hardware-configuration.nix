# --- parts/hosts/pupibundle/hardware-configuration.nix
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
{ pkgs, ... }:
let
  argonFanScript = pkgs.writeShellScript "argonone-fan-curve" ''
    set -euo pipefail

    I2C_BUS="''${I2C_BUS:-1}"
    I2C_ADDR="''${I2C_ADDR:-0x1a}"
    PWM_REG="''${PWM_REG:-0x80}"

    # Defaults (OEM-like)
    FAN_T0="''${FAN_T0:-55}"
    FAN_T1="''${FAN_T1:-60}"
    FAN_T2="''${FAN_T2:-65}"

    FAN_S0="''${FAN_S0:-10}"    # %
    FAN_S1="''${FAN_S1:-55}"    # %
    FAN_S2="''${FAN_S2:-100}"   # %

    HYST="''${HYST:-3}"         # °C

    STATE="/run/argonone-fan.level"

    temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))

    toHex() {
      local p="$1"
      if [ "$p" -lt 0 ]; then p=0; fi
      if [ "$p" -gt 100 ]; then p=100; fi
      printf '0x%02x' "$p"
    }

    level="$(cat "$STATE" 2>/dev/null || echo 0)"

    up0="$FAN_T0"
    up1="$FAN_T1"
    up2="$FAN_T2"

    down1=$(( FAN_T0 - HYST ))
    down2=$(( FAN_T1 - HYST ))
    down3=$(( FAN_T2 - HYST ))

    # hysteresis-based state machine
    while :; do
      old="$level"
      case "$level" in
        0)
          if [ "$temp" -ge "$up0" ]; then level=1; fi
          ;;
        1)
          if [ "$temp" -ge "$up1" ]; then level=2
          elif [ "$temp" -le "$down1" ]; then level=0
          fi
          ;;
        2)
          if [ "$temp" -ge "$up2" ]; then level=3
          elif [ "$temp" -le "$down2" ]; then level=1
          fi
          ;;
        3)
          if [ "$temp" -le "$down3" ]; then level=2; fi
          ;;
        *)
          level=0
          ;;
      esac
      [ "$level" = "$old" ] && break
    done

    case "$level" in
      0) pct=0 ;;
      1) pct="$FAN_S0" ;;
      2) pct="$FAN_S1" ;;
      3) pct="$FAN_S2" ;;
    esac

    hex="$(toHex "$pct")"

    # Write only if changed (avoid bus spam)
    lastHexFile="/run/argonone-fan.lasthex"
    lastHex="$(cat "$lastHexFile" 2>/dev/null || true)"

    if [ "$hex" != "$lastHex" ]; then
      ${pkgs.i2c-tools}/bin/i2cset -y "$I2C_BUS" "$I2C_ADDR" "$PWM_REG" "$hex"
      echo "$hex" > "$lastHexFile"
    fi

    echo "$level" > "$STATE"
  '';
in
{
  hardware.enableRedistributableFirmware = true;
  boot.loader.raspberryPi.bootloader = "kernel";

  hardware.i2c.enable = true;
  boot.kernelModules = [ "i2c-dev" ];
  environment.systemPackages = [
    pkgs.i2c-tools
  ];

  hardware.raspberry-pi.config = {
    all = {
      options = {
        # recommended by argononed docs for Pi5 + Argon ONE V3 setups
        usb_max_current_enable = {
          enable = true;
          value = "1";
        };
      };
      base-dt-params = {
        i2c_arm = {
          enable = true;
          value = "on";
        };
      };
    };
  };

  systemd.services.argonone-fan = {
    description = "Argon ONE V3 fan curve (OEM-like AUTO + hysteresis)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = argonFanScript;

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      # allow writing our state files
      ReadWritePaths = [
        "/run"
        "/sys/class/thermal"
        "/dev"
      ];
    };
    # NOTE: override defaults
    environment = {
      FAN_T0 = "50";
      FAN_T1 = "55";
      FAN_T2 = "65";
    };
  };

  systemd.timers.argonone-fan = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20s";
      OnUnitActiveSec = "10s";
      AccuracySec = "2s";
    };
  };

  # SSD optimizations
  services.fstrim.enable = true;
  boot.tmp.useTmpfs = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 20;
    priority = 100;
  };

  boot.kernel.sysctl."vm.swappiness" = 100;
}
