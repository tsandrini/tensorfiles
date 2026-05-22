# --- flake-parts/modules/nixos/security/hardening/server.nix
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
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.security.hardening.server;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.security.hardening.server = {
    enable = mkEnableOption ''
      Enables the **server** security hardening profile.

      Inherits `tensorfiles.security.hardening.base` and adds per-netns
      network sysctls and brute-force protection. Designed to work both
      on bare-metal/VM servers and inside NixOS LXCs — settings that
      require kernel-cmdline control are inherited from `base`, which is
      already gated on `!boot.isContainer`.

      Sshd lockdown is intentionally not duplicated here; it lives in
      `tensorfiles.services.networking.ssh` and is applied wherever sshd
      is enabled.

      Intended for headless hosts (VPS, work LXCs, home server).
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.security.hardening.base.enable = _ true;

      # Per-netns network sysctls. These DO apply inside an LXC.
      boot.kernel.sysctl = {
        # SYN flood protection (NixOS default; restated for intent).
        "net.ipv4.tcp_syncookies" = _ 1;

        # Loose reverse-path filtering. Strict (=1) silently drops return
        # packets when the inbound interface differs from the outbound one,
        # which breaks asymmetric routing over WireGuard/Tailscale.
        # Loose (=2) still drops obvious spoofing.
        "net.ipv4.conf.all.rp_filter" = _ 2;
        "net.ipv4.conf.default.rp_filter" = _ 2;

        # Don't accept ICMP redirects — no legitimate use on a server.
        "net.ipv4.conf.all.accept_redirects" = _ 0;
        "net.ipv4.conf.default.accept_redirects" = _ 0;
        "net.ipv6.conf.all.accept_redirects" = _ 0;
        "net.ipv6.conf.default.accept_redirects" = _ 0;

        # Don't accept source-routed packets (MITM vector).
        "net.ipv4.conf.all.accept_source_route" = _ 0;
        "net.ipv4.conf.default.accept_source_route" = _ 0;
        "net.ipv6.conf.all.accept_source_route" = _ 0;
        "net.ipv6.conf.default.accept_source_route" = _ 0;

        # Log packets with impossible source addresses.
        "net.ipv4.conf.all.log_martians" = _ 1;

        # Don't reply to broadcast pings (Smurf amplification).
        "net.ipv4.icmp_echo_ignore_broadcasts" = _ 1;
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
