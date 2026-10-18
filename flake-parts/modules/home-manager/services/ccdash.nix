# --- flake-parts/modules/home-manager/services/ccdash.nix
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
  inputs,
  secretsPath,
}:
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    ;
  inherit (builtins) pathExists;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.services.ccdash;
  claudeCodeCfg = config.tensorfiles.hm.programs.claude-code;
  _ = mkOverrideAtHmModuleLevel;

  dmsCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.dank-material-shell";
  niriCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake";

  notifySecret = cfg.notify.tokenSecretPath;
  notifyCheck =
    cfg.notify.enable
    && (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix")
    && pathExists (secretsPath + "/${notifySecret}.age");

  ccstatuslineCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.claude-code")
    && claudeCodeCfg.statusline.enable;
in
{
  options.tensorfiles.hm.services.ccdash = {
    enable = mkEnableOption ''
      ccdash, the live dashboard for running Claude Code sessions: the
      collector daemon, the Claude Code hooks feeding it, and the statusline
      wrapper (kept in front of ccstatusline when that is enabled)
    '';

    channel.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to start interactive Claude Code sessions with the ccdash
        channel, so the web UI can reply to them. Needs
        `programs.ccdash.channel.allow` on the NixOS host, otherwise Claude
        Code skips the channel.
      '';
    };

    telemetry.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether Claude Code exports OpenTelemetry metrics and events to the
        ccdash daemon (loopback only), for tokens, cache hits, API latency,
        commits and edit decisions in the analytics view.
      '';
    };

    notify = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to push prompts and finished turns to the phone through
          ntfy, with buttons that answer the prompts. Needs the
          `tensorfiles.hm.security.agenix` backend and the token secret
          (`tokenSecretPath`); stays off until that secret exists.
        '';
      };

      url = mkOption {
        type = types.str;
        default = "https://ntfy.home.tsandrini.sh";
        description = "The ntfy server.";
      };

      topic = mkOption {
        type = types.str;
        default = "ccdash";
        description = "The ntfy topic notifications go to.";
      };

      webUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://10.10.0.204:7837";
        description = ''
          How the phone reaches the daemon, for the buttons and taps. `null`
          uses this machine's LAN address and {option}`port`.
        '';
      };

      tokenSecretPath = mkOption {
        type = types.str;
        default = "common/ccdash-ntfy-token";
        description = ''
          Secret holding an ntfy access token that may publish to the topic,
          relative to the secrets dir and without the `.age` suffix.
        '';
      };
    };

    port = mkOption {
      type = types.port;
      default = 7837;
      description = ''
        Port of the HTTP API and web UI, bound on all addresses.
        Reachability is up to the host firewall.
      '';
    };

    binds = {
      dash = mkOption {
        type = types.str;
        default = "Mod+C";
        description = "niri bind toggling the ccdash tab of the DMS dash.";
      };

      focusWaiting = mkOption {
        type = types.str;
        default = "Mod+Shift+C";
        description = ''
          niri bind focusing the session that has waited longest on you
          (permission prompts first).
        '';
      };
    };

    workspaces = mkOption {
      type = types.listOf types.str;
      default = [
        "~/ProjectBundle/meteopress"
        "~/ProjectBundle/PesekMudra"
        "~/ProjectBundle/tsandrini"
      ];
      description = ''
        Workspace directories the web UI can filter sessions by, named by
        their last path component (`~/` is the home directory).
      '';
    };
  };

  imports = [ inputs.ccdash.homeModules.default ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      services.ccdash = {
        enable = _ true;
        settings.http.listen = _ [ "[::]:${toString cfg.port}" ];
        settings.workspaces.dirs = _ cfg.workspaces;
        claudeCode.channel.enable = _ cfg.channel.enable;
        claudeCode.telemetry.enable = _ cfg.telemetry.enable;
        claudeCode.statusLine = {
          enable = _ true;
          command = mkIf ccstatuslineCheck (_ (getExe claudeCodeCfg.statusline.package));
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf notifyCheck {
      age.secrets."${notifySecret}".file = _ (secretsPath + "/${notifySecret}.age");

      services.ccdash.settings.notify = {
        url = _ cfg.notify.url;
        topic = _ cfg.notify.topic;
        token_file = _ config.age.secrets."${notifySecret}".path;
      }
      // optionalAttrs (cfg.notify.webUrl != null) { web_url = _ cfg.notify.webUrl; };
    })
    # |----------------------------------------------------------------------| #
    (mkIf dmsCheck {
      services.ccdash.dms.enable = _ true;
    })
    # |----------------------------------------------------------------------| #
    (mkIf (dmsCheck && niriCheck) {
      programs.niri.settings.binds =
        let
          dms =
            cmd:
            _ (
              config.lib.niri.actions.spawn (
                [
                  "dms"
                  "ipc"
                  "call"
                ]
                ++ cmd
              )
            );
        in
        {
          "${cfg.binds.dash}".action = dms [
            "dash"
            "toggle"
            "plugin_ccdash"
          ];
          "${cfg.binds.focusWaiting}".action = dms [
            "ccdash"
            "focusWaiting"
          ];
        };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
