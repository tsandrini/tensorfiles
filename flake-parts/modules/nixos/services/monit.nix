# --- flake-parts/modules/nixos/services/monit.nix
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
  localFlake,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib)
    mkIf
    types
    mkMerge
    mkEnableOption
    mkOption
    ;
  inherit (localFlake.lib.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.services.monit;
  _ = mkOverrideAtProfileLevel;

  defaultDomain = "tsandrini.sh";
in
{
  options.tensorfiles.services.monit = {
    enable = mkEnableOption ''
      TODO
    '';

    alertAddress = mkOption {
      type = types.nullOr types.str;
      default = "";
      description = ''
        Email address to send alerts to.
        This is used by the monit service.
      '';
    };

    checkInterval = mkOption {
      type = types.int;
      default = 120;
      description = ''
        Interval in seconds to check the services.
      '';
    };

    startDelay = mkOption {
      type = types.nullOr types.int;
      default = 60;
      description = ''
        Delay in seconds to start the monit service.
        If this is set to null, the service will start immediately,
        or rather the start delay line will not be added to the config.
      '';
    };

    extraConfigPre = mkOption {
      type = types.str;
      default = "";
      description = ''
        Extra configuration to add to the monit config.
        This is prepended to the actual generated config.
      '';
    };

    extraConfigPost = mkOption {
      type = types.str;
      default = "";
      description = ''
        Extra configuration to add to the monit config.
        This is appended to the actual generated config.
      '';
    };

    httpd = {
      enable = mkEnableOption ''
        TODO
      '';

      port = mkOption {
        type = types.int;
        default = 2812;
        description = ''
          Port to listen on for the monit web interface.
          This is used by the monit service.
        '';
      };

      address = mkOption {
        type = types.nullOr types.str;
        default = "localhost";
        description = ''
          Address to listen on for the monit web interface.
          This is used by the monit service.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = "admin";
        description = ''
          User to use for the monit web interface.
          This is used by the monit service.
        '';
      };

      # TODO not sure
      password = mkOption {
        type = types.nullOr types.str;
        default = "";
        description = ''
          Password to use for the monit web interface.
          This is used by the monit service.
        '';
      };
    };

    # TODO add support for remote mailserver
    mailserver = {
      enable = mkEnableOption ''
        Enable the mailserver for monit which is used to send alerts.
        This can be either localhost or a remote server.
      '';
    };

    checks = {

      filesystem = {
        root = {
          enable = mkEnableOption ''
            Enable the filesystem check for monit.
            This is used by the monit service.
          '';

          threshold = mkOption {
            type = types.int;
            default = 80;
            description = ''
              Threshold for the filesystem check.
              This is used by the monit service.
            '';
          };
        };
      };

      system = {

        enable = mkEnableOption ''
          Enable the system check for monit.
          This is used by the monit service.
        '';

        cpu = {
          enable =
            mkEnableOption ''
              Append the cpu check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 95;
            description = ''
              Threshold for the cpu check.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 10;
            description = ''
              Number of cycles needed to fail for the cpu check
              to trigger an alert.
            '';
          };
        };

        memory = {
          enable =
            mkEnableOption ''
              Append the memory check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 75;
            description = ''
              Threshold for the memory check.
            '';
          };
          num_cycles = mkOption {
            type = types.int;
            default = 5;
            description = ''
              Number of cycles needed to fail for the memory check
              to trigger an alert.
            '';
          };
        };

        swap = {
          enable =
            mkEnableOption ''
              Append the swap check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 20;
            description = ''
              Threshold for the swap check.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 10;
            description = ''
              Number of cycles needed to fail for the swap check
              to trigger an alert.
            '';
          };
        };

        loadavg_1min = {
          enable =
            mkEnableOption ''
              Append the loadavg (1min) check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 98;
            description = ''
              Threshold for the loadavg check.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 15;
            description = ''
              Number of cycles needed to fail for the loadavg check
              to trigger an alert.
            '';
          };
        };

        loadavg_5min = {
          enable =
            mkEnableOption ''
              Append the loadavg (5min) check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 90;
            description = ''
              Threshold for the loadavg check.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 10;
            description = ''
              Number of cycles needed to fail for the loadavg check
              to trigger an alert.
            '';
          };
        };

        loadavg_15min = {
          enable =
            mkEnableOption ''
              Append the loadavg (15min) check to the system check for monit.
              For this to be enabled, the parent system check must be enabled.
            ''
            // {
              default = true;
            };

          threshold = mkOption {
            type = types.int;
            default = 85;
            description = ''
              Threshold for the loadavg check.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 8;
            description = ''
              Number of cycles needed to fail for the loadavg check
              to trigger an alert.
            '';
          };
        };

      };

      processes = {
        sshd = {
          enable = mkEnableOption ''
            Enable the sshd check for monit.
          '';

          pidfile = mkOption {
            type = types.str;
            default = "/var/run/sshd.pid";
            description = ''
              PID file for the sshd process.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 2;
            description = ''
              Number of cycles needed to fail for the sshd check
              to trigger an alert.
            '';
          };

          port = mkOption {
            type = types.int;
            default = 22;
            description = ''
              Port for the sshd check.
            '';
          };

          start_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl start sshd";
            description = ''
              Command to start the sshd process.
            '';
          };

          stop_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl stop sshd";
            description = ''
              Command to stop the sshd process.
            '';
          };

        };

        postfix = {
          enable = mkEnableOption ''
            Enable the postfix check for monit.
          '';

          pidfile = mkOption {
            type = types.str;
            default = "/var/lib/postfix/queue/pid/master.pid";
            description = ''
              PID file for the postfix process.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 5;
            description = ''
              Number of cycles needed to fail for the postfix check
              to trigger an alert.
            '';
          };

          port = mkOption {
            type = types.int;
            default = 25;
            description = ''
              Port for the postfix check.
            '';
          };

          start_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl start postfix";
            description = ''
              Command to start the postfix process.
            '';
          };

          stop_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl stop postfix";
            description = ''
              Command to stop the postfix process.
            '';
          };
        };

        dovecot = {
          enable = mkEnableOption ''
            Enable the dovecot check for monit.
          '';

          pidfile = mkOption {
            type = types.str;
            default = "/var/run/dovecot2/master.pid";
            description = ''
              PID file for the dovecot process.
            '';
          };

          num_cycles = mkOption {
            type = types.int;
            default = 5;
            description = ''
              Number of cycles needed to fail for the dovecot check
              to trigger an alert.
            '';
          };

          start_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl start dovecot2";
            description = ''
              Command to start the dovecot process.
            '';
          };

          stop_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl stop dovecot2";
            description = ''
              Command to stop the dovecot process.
            '';
          };

          port = mkOption {
            type = types.int;
            default = 993;
            description = ''
              Port for the dovecot check.
            '';
          };

          fqdn = mkOption {
            type = types.str;
            default = defaultDomain;
            description = ''
              FQDN for the dovecot check.
              This is used by the monit service.
            '';
          };
        };

        rspamd = {
          enable = mkEnableOption ''
            Enable the rspamd check for monit.
          '';

          process_match_str = mkOption {
            type = types.str;
            default = "rspamd: main process";
            description = ''
              Process match string for the rspamd process.
            '';
          };

          start_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl start rspamd";
            description = ''
              Command to start the rspamd process.
            '';
          };

          stop_program = mkOption {
            type = types.str;
            default = "${pkgs.systemd}/bin/systemctl stop rspamd";
            description = ''
              Command to stop the rspamd process.
            '';
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.monit = {
        enable = _ true;
        config =
          let
            generatedConfig = ''
              ${
                if cfg.alertAddress != "" then
                  ''
                    set alert ${cfg.alertAddress}
                  ''
                else
                  ""
              }

              set daemon ${toString cfg.checkInterval} ${
                if cfg.startDelay != null then "with start delay ${toString cfg.startDelay}" else ""
              }

              ${
                if cfg.mailserver.enable then
                  ''
                    set mailserver localhost
                  ''
                else
                  ""
              }

              ${
                with cfg.httpd;
                if enable then
                  ''
                    set httpd port ${toString port} and use address ${address}
                      allow localhost
                      allow ${user}:${password}
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.filesystem.root;
                if enable then
                  ''
                    check filesystem root with path /
                      if space usage > ${toString threshold}% then alert
                      if inode usage > ${toString threshold}% then alert
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.system;
                if enable then
                  ''
                    check system $HOST
                      ${
                        if cpu.enable then
                          "if cpu usage > ${toString cpu.threshold}% for ${toString cpu.num_cycles} cycles then alert"
                        else
                          ""
                      }
                      ${
                        if memory.enable then
                          "if memory usage > ${toString memory.threshold}% for ${toString memory.num_cycles} cycles then alert"
                        else
                          ""
                      }
                      ${
                        if swap.enable then
                          "if swap usage > ${toString swap.threshold}% for ${toString swap.num_cycles} cycles then alert"
                        else
                          ""
                      }
                      ${
                        if loadavg_1min.enable then
                          "if loadavg (1 min) > ${toString loadavg_1min.threshold} for ${toString loadavg_1min.num_cycles} cycles then alert"
                        else
                          ""
                      }
                      ${
                        if loadavg_5min.enable then
                          "if loadavg (5 min) > ${toString loadavg_5min.threshold} for ${toString loadavg_5min.num_cycles} cycles then alert"
                        else
                          ""
                      }
                      ${
                        if loadavg_15min.enable then
                          "if loadavg (15 min) > ${toString loadavg_15min.threshold} for ${toString loadavg_15min.num_cycles} cycles then alert"
                        else
                          ""
                      }
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.processes.sshd;
                if enable then
                  ''
                    check process sshd with pidfile ${pidfile}
                      start program = "${start_program}"
                      stop program = "${stop_program}"
                      if failed port ${toString port} protocol ssh for ${toString num_cycles} cycles then restart
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.processes.postfix;
                if enable then
                  ''
                    check process postfix with pidfile ${pidfile}
                      start program = "${start_program}"
                      stop program = "${stop_program}"
                      if failed port ${toString port} protocol smtp for ${toString num_cycles} cycles then restart
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.processes.dovecot;
                if enable then
                  ''
                    check process dovecot with pidfile ${pidfile}
                      start program = "${start_program}"
                      stop program = "${stop_program}"
                      if failed host ${fqdn} port ${toString port} type tcpssl sslauto protocol imap for ${toString num_cycles} cycles then restart
                  ''
                else
                  ""
              }

              ${
                with cfg.checks.processes.rspamd;
                if enable then
                  ''
                    check process rspamd with matching "${process_match_str}"
                      start program = "${start_program}"
                      stop program = "${stop_program}"
                  ''
                else
                  ""
              }
            '';
          in
          ''
            ${cfg.extraConfigPre}
            ${generatedConfig}
            ${cfg.extraConfigPost}
          '';
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
