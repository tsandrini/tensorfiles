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
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
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

        system.users = {
          enable = _ true;
          usersSettings = {
            "root" = { };
          };
        };
      };

      services.logrotate = {
        enable = _ true;
        settings = {
          header.dateext = _ true; # Rotated logs will have the date in their name (e.g., logfile-YYYYMMDD)
          fail2ban = {
            files = "/var/log/fail2ban/*.log"; # Explicitly the file to rotate
            create = "0600 root root";

            postrotate = ''
              # Check if fail2ban service is active
              if ${config.systemd.package}/bin/systemctl is-active --quiet fail2ban.service; then
                # Command fail2ban to set its log target to the new file.
                ${pkgs.fail2ban}/bin/fail2ban-client set logtarget /var/log/fail2ban.log > /dev/null
                # As a fallback if the above fails (e.g., command error), try sending SIGUSR1
                if [ $? -ne 0 ]; then
                  ${config.systemd.package}/bin/systemctl kill -s USR1 fail2ban.service > /dev/null || true
                fi
              fi
            '';
          };
        };
      };

      services.fail2ban = {
        enable = _ true;
        maxretry = _ 6;
        bantime = _ "11m";
        bantime-increment = {
          enable = _ true;
          rndtime = _ "7m";
          overalljails = _ true;
        };
      };

      networking.nftables.enable = _ true;
      networking.firewall = {
        enable = _ true;
        pingLimit =
          if config.networking.nftables.enable then "2/second" else "--limit 1/minute --limit-burst 5";
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
