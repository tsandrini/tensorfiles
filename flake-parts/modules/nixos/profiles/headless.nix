# --- flake-parts/modules/nixos/profiles/headless.nix
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
    getExe
    ;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.profiles.headless;
  _ = mkOverrideAtProfileLevel;
in
{
  options.tensorfiles.profiles.headless = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the headless system profile.

      **Headless layer** builds on top of the minimal layer and adds other
      server-like functionality like simple shells, basic networking for remote
      access and simple editors.
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles = {
        profiles.minimal.enable = _ true;

        services.networking.networkmanager.enable = _ true;
        services.networking.ssh.enable = _ true;
        services.fail2ban.enable = _ true;
      };

      programs.bash = {
        interactiveShellInit = lib.mkBefore ''
          ${getExe pkgs.microfetch}
          last -x --fulltimes --limit 30
        '';
      };

      services.openssh.openFirewall = false;

      tensorfiles.networking.firewall.subnets-firewall = {
        defaultSubnets = {
          allowedTCPPorts = config.services.openssh.ports;
        };
      };

      services.getty.autologinUser = _ "root";

      networking.nftables.enable = _ true;
      networking.firewall = {
        enable = _ true;
        pingLimit = _ (
          if config.networking.nftables.enable then "2/second" else "--limit 1/minute --limit-burst 5"
        );
      };

      # NOTE: rsyslog is intentionally not enabled. journald handles log
      # storage and rotation natively, and Promtail reads from the journal
      # directly. rsyslog would only produce duplicate text log files on
      # disk (~530MB closure cost).
      services.journald.extraConfig = _ ''
        SystemMaxUse=100M
        MaxRetentionSec=7day
      '';
      services.logrotate.enable = _ true;
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
