# --- flake-parts/modules/nixos/services/wivrn.nix
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
{ localFlake }:
{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.services.wivrn;
  _ = mkOverrideAtModuleLevel;

  # NOTE: WiVRn's fixed TCP+UDP port, see services.wivrn.openFirewall upstream
  port = 9757;

  subnetsFirewallCheck = isModuleLoadedAndEnabled config "tensorfiles.networking.firewall.subnets-firewall";
in
{
  options.tensorfiles.services.wivrn = {
    enable = mkEnableOption ''
      Enables WiVRn, the OpenXR streaming server for standalone headsets
      (Meta Quest, Pico, ...), started with the user session. On top of the
      upstream `services.wivrn` module this

      - starts the server at login (`autoStart`) with `cap_sys_nice` for
        asynchronous reprojection (`highPriority`; drops the unit's systemd
        sandboxing),
      - wires Steam in when `programs.steam` is enabled: the configured Steam
        package for the headset's app launcher and
        `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES` so pressure-vessel games
        find the runtime (takes effect after a re-login),
      - retries the user unit on failure: a switch can start it before
        `/run/wrappers` is recreated, which fails with exit status 127.

      The headset app (store: `org.meumeu.wivrn`) must run the same WiVRn
      version as the server. A new headset is paired with `wivrnctl pair`,
      the PIN shows up as a desktop notification. For a desktop inside VR see
      `tensorfiles.hm.programs.wayvr`.
    '';

    openFirewall =
      mkEnableOption ''
        opening WiVRn's port (${toString port}, TCP and UDP). With
        `tensorfiles.networking.firewall.subnets-firewall` enabled the port is
        only opened for its default subnets, otherwise globally. Avahi's mDNS
        port, needed for discovery, is opened by the Avahi module itself.
      ''
      // {
        default = true;
      };

    gpu = mkOption {
      type = types.nullOr (types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}");
      default = null;
      example = "1002:7550";
      description = ''
        PCI `vendor:device` id (`lspci -nn`) of the GPU the compositor and the
        video encoder should use, passed to Mesa's device-select layer as
        `MESA_VK_DEVICE_SELECT=<id>!` (only that device is exposed). Set it
        on machines whose iGPU and dGPU share a vendor id, where vendor-based
        heuristics can't tell them apart. `null` leaves the choice to Monado.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.wivrn = {
        enable = _ true;
        autoStart = _ true;
        highPriority = _ true;
      };

      systemd.user.services.wivrn.serviceConfig = {
        Restart = _ "on-failure";
        RestartSec = _ 2;
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf config.programs.steam.enable {
      services.wivrn.steam = {
        package = _ config.programs.steam.package;
        importOXRRuntimes = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.gpu != null) {
      # NOTE: plain attrs, merges with the host's own Monado environment
      services.wivrn.monadoEnvironment.MESA_VK_DEVICE_SELECT = "${cfg.gpu}!";
    })
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.openFirewall && subnetsFirewallCheck) {
      # NOTE: plain lists, merge with the host's ports
      tensorfiles.networking.firewall.subnets-firewall.defaultSubnets = {
        allowedTCPPorts = [ port ];
        allowedUDPPorts = [ port ];
      };
    })
    (mkIf (cfg.openFirewall && !subnetsFirewallCheck) {
      services.wivrn.openFirewall = _ true;
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
