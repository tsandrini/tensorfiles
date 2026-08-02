# --- flake-parts/nixos/modules/networking/wireguard-endpoint-watchdog.nix
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
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    mapAttrs'
    nameValuePair
    mapAttrsToList
    ;

  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.networking.wireguard-endpoint-watchdog;
  _ = mkOverrideAtModuleLevel;

  unitName = ifaceName: "wg-endpoint-watchdog-${ifaceName}";

  # NOTE: `wg set <if> peer <k> endpoint <host>:<port>` resolves via getaddrinfo
  # and latches the *first* result forever -- the kernel never re-resolves. On a
  # dual-stack host that pick is a boot-time race between the A and the AAAA
  # record. This watchdog takes ownership of the endpoint instead: it resolves a
  # single, explicit address family and re-applies the result whenever the
  # handshake goes stale.
  mkWatchdogScript =
    ifaceName: icfg:
    pkgs.writeShellApplication {
      name = "${unitName ifaceName}-run";
      runtimeInputs = with pkgs; [
        wireguard-tools
        getent
        gawk
        coreutils
        systemd
      ];
      text = ''
        IFACE=${lib.escapeShellArg ifaceName}
        PUBKEY=${lib.escapeShellArg icfg.peerPublicKey}
        HOST=${lib.escapeShellArg icfg.endpointHost}
        PORT=${toString icfg.endpointPort}
        FAMILY=${lib.escapeShellArg icfg.addressFamily}
        STALE=${toString icfg.staleHandshakeSeconds}
        MAX_FAILS=${toString icfg.restartAfterFailures}

        STATE_DIR=/run/${unitName ifaceName}
        FAIL_FILE=$STATE_DIR/consecutive-failures
        mkdir -p "$STATE_DIR"
        [ -f "$FAIL_FILE" ] || echo 0 >"$FAIL_FILE"
        fails=$(cat "$FAIL_FILE")

        # Resolve strictly within the configured family. Anything outside it is
        # not a fallback -- it is the failure mode we exist to prevent.
        resolve() {
          if [ "$FAMILY" = "ipv4" ]; then
            getent ahostsv4 "$HOST" | awk '/STREAM/ {print $1; exit}'
          else
            getent ahostsv6 "$HOST" | awk '/STREAM/ && $1 ~ /:/ {print $1; exit}'
          fi
        }

        if ! ip=$(resolve) || [ -z "$ip" ]; then
          echo "watchdog: cannot resolve $HOST as $FAMILY, leaving endpoint untouched"
          exit 0
        fi

        if [ "$FAMILY" = "ipv4" ]; then
          want="$ip:$PORT"
        else
          want="[$ip]:$PORT"
        fi

        if ! wg show "$IFACE" >/dev/null 2>&1; then
          echo "watchdog: interface $IFACE is absent, nothing to do"
          exit 0
        fi

        hs=$(wg show "$IFACE" latest-handshakes | awk -v k="$PUBKEY" '$1 == k {print $2; exit}')
        have=$(wg show "$IFACE" endpoints | awk -v k="$PUBKEY" '$1 == k {print $2; exit}')
        : "''${hs:=0}"

        now=$(date +%s)
        if [ "$hs" -gt 0 ]; then
          age=$((now - hs))
        else
          age=$((STALE + 1))
        fi

        if [ "$age" -le "$STALE" ]; then
          # Healthy. Still correct a drifted endpoint so that a roamed peer does
          # not silently outlive the address we actually want to talk to.
          if [ "$have" != "$want" ]; then
            echo "watchdog: healthy but endpoint drifted ($have -> $want), re-pinning"
            wg set "$IFACE" peer "$PUBKEY" endpoint "$want"
          fi
          echo 0 >"$FAIL_FILE"
          exit 0
        fi

        echo "watchdog: handshake stale (''${age}s > ''${STALE}s), endpoint=''${have:-none} want=$want"

        # Cheap fix first: the address is wrong, or the kernel latched a roamed
        # source that has since died. Re-applying costs one netlink call.
        if [ "$have" != "$want" ]; then
          echo "watchdog: re-pinning endpoint to $want"
          wg set "$IFACE" peer "$PUBKEY" endpoint "$want"
          echo 0 >"$FAIL_FILE"
          exit 0
        fi

        # Endpoint was already correct and it still will not handshake, so the
        # local interface state is what is wedged. Escalate.
        fails=$((fails + 1))
        echo "$fails" >"$FAIL_FILE"
        echo "watchdog: endpoint already correct, consecutive failures=$fails/$MAX_FAILS"

        if [ "$fails" -ge "$MAX_FAILS" ]; then
          echo "watchdog: restarting wireguard-$IFACE.service"
          systemctl restart "wireguard-$IFACE.service" || true
          # The peer unit does not re-run on its own, so re-assert the endpoint.
          sleep 2
          wg set "$IFACE" peer "$PUBKEY" endpoint "$want" || true
          echo 0 >"$FAIL_FILE"
        fi
      '';
    };
in
{
  options.tensorfiles.networking.wireguard-endpoint-watchdog = {
    enable = mkEnableOption ''
      Keeps WireGuard peer endpoints correct and the tunnel handshaking without
      manual intervention.

      The upstream `networking.wireguard` peer unit is a `Type=oneshot` that
      resolves its endpoint exactly once at boot, so a hostname with both an A
      and an AAAA record is a coin flip that then gets frozen for the lifetime
      of the machine. This module resolves one explicit address family on a
      timer, re-pins the endpoint whenever the handshake goes stale, and
      restarts the interface if re-pinning alone does not recover it.
    '';

    interfaces = mkOption {
      type = types.attrsOf (
        types.submodule (_ignored: {
          options = {
            peerPublicKey = mkOption {
              type = types.str;
              description = "Public key of the peer whose endpoint should be watched.";
              example = "RY2XHIRk+2RtA27EUQdLj+CcqAP2Izj4cGI3Nm0d5CE=";
            };

            endpointHost = mkOption {
              type = types.str;
              description = ''
                Hostname of the peer endpoint. Resolved on every tick, so a
                changing home IP is picked up without a redeploy.
              '';
              example = "vpn.tsandrini.sh";
            };

            endpointPort = mkOption {
              type = types.port;
              description = "UDP port of the peer endpoint.";
              example = 51821;
            };

            addressFamily = mkOption {
              type = types.enum [
                "ipv4"
                "ipv6"
              ];
              default = "ipv4";
              description = ''
                Address family to resolve `endpointHost` within. Deliberately
                not dual-stack: the whole point is that the choice is explicit
                and reproducible rather than decided by getaddrinfo ordering.
              '';
            };

            interval = mkOption {
              type = types.str;
              default = "60s";
              description = "systemd time span between watchdog runs.";
            };

            staleHandshakeSeconds = mkOption {
              type = types.int;
              default = 180;
              description = ''
                Handshake age past which the tunnel counts as broken. WireGuard
                rekeys about every 120s under traffic, and `persistentKeepalive`
                keeps it ticking otherwise, so 180s is comfortably past healthy.
              '';
            };

            restartAfterFailures = mkOption {
              type = types.int;
              default = 3;
              description = ''
                Consecutive stale checks with an already-correct endpoint before
                the interface unit is restarted.
              '';
            };
          };
        })
      );
      default = { };
      description = "WireGuard interfaces to watch, keyed by interface name.";
    };
  };

  config = mkIf (cfg.enable && cfg.interfaces != { }) (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      systemd.services = mapAttrs' (
        ifaceName: icfg:
        nameValuePair (unitName ifaceName) {
          description = _ "WireGuard endpoint watchdog - ${ifaceName}";
          after = _ [
            "wireguard-${ifaceName}.service"
            "network-online.target"
            "nss-lookup.target"
          ];
          wants = _ [
            "network-online.target"
            "nss-lookup.target"
          ];
          serviceConfig = {
            Type = _ "oneshot";
            ExecStart = _ (lib.getExe (mkWatchdogScript ifaceName icfg));
          };
        }
      ) cfg.interfaces;
    }
    # |----------------------------------------------------------------------| #
    {
      systemd.timers = mapAttrs' (
        ifaceName: icfg:
        nameValuePair (unitName ifaceName) {
          description = _ "WireGuard endpoint watchdog timer - ${ifaceName}";
          wantedBy = _ [ "timers.target" ];
          timerConfig = {
            OnBootSec = _ "30s";
            OnUnitActiveSec = _ icfg.interval;
            AccuracySec = _ "1s";
          };
        }
      ) cfg.interfaces;
    }
    # |----------------------------------------------------------------------| #
    {
      # Fail the build rather than the tunnel if a watched interface is not
      # actually declared -- a typo here is otherwise invisible until an outage.
      assertions = mapAttrsToList (ifaceName: _icfg: {
        assertion = config.networking.wireguard.interfaces ? ${ifaceName};
        message = ''
          tensorfiles.networking.wireguard-endpoint-watchdog.interfaces."${ifaceName}"
          has no matching networking.wireguard.interfaces."${ifaceName}".
        '';
      }) cfg.interfaces;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
