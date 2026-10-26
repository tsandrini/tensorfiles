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
  hostName,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (builtins) pathExists;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.services.ccdash;
  claudeCodeCfg = config.tensorfiles.hm.programs.claude-code;
  _ = mkOverrideAtHmModuleLevel;

  dmsCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.dank-material-shell";
  niriCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake";

  tokenSecret = cfg.hub.tokenSecretPath;
  tokenCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix")
    && pathExists (secretsPath + "/${tokenSecret}.age");

  ccstatuslineCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.claude-code")
    && claudeCodeCfg.statusline.enable;
in
{
  options.tensorfiles.hm.services.ccdash = {
    enable = mkEnableOption ''
      the ccdash collector: reports this machine's Claude Code sessions to
      the hub (pupibundle), with the Claude Code hooks feeding it and the
      statusline wrapper (kept in front of ccstatusline when that is
      enabled). Needs the collector token secret (`hub.tokenSecretPath`)
      and the `tensorfiles.hm.security.agenix` backend; stays off until the
      secret exists
    '';

    hub = {
      url = mkOption {
        type = types.str;
        default = "wss://ccdash.home.tsandrini.sh/collect";
        description = "The hub's `/collect` endpoint.";
      };

      tokenSecretPath = mkOption {
        type = types.str;
        default = "common/ccdash-collector-token-${hostName}";
        description = ''
          Secret holding this machine's collector token (the hub lists it
          under this host name), relative to the secrets dir and without
          the `.age` suffix.
        '';
      };
    };

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

    sync.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this machine's Claude Code state (sessions, rewind
        checkpoints, plans, tasks, pasted content, the prompt history) is
        kept in step with the hub, so a session ended here resumes on the
        other workstations; the hub also refuses prompts in a session open
        on another machine. Replaces handoff's former `[claude]` unit.
      '';
    };

    telemetry.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether Claude Code exports OpenTelemetry metrics and events to the
        collector (loopback only), which forwards the kept records to the
        hub for tokens, cache hits, API latency, commits and edit decisions
        in the analytics view.
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
  };

  imports = [ inputs.ccdash.homeModules.default ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      warnings = lib.optional (!tokenCheck) ''
        tensorfiles.hm.services.ccdash: the collector token secret
        ${tokenSecret}.age is missing, ccdash stays off on ${hostName}.
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf tokenCheck {
      age.secrets."${tokenSecret}".file = _ (secretsPath + "/${tokenSecret}.age");

      services.ccdash = {
        enable = _ true;
        hub.url = _ cfg.hub.url;
        hub.tokenFile = _ config.age.secrets."${tokenSecret}".path;
        sync.enable = _ cfg.sync.enable;
        # NOTE: the meta tokens direnv injects at the workspace root (claude-code module)
        launch.env = _ [ "CLAUDE_META_*" ];
        claudeCode.channel.enable = _ cfg.channel.enable;
        claudeCode.telemetry.enable = _ cfg.telemetry.enable;
        claudeCode.statusLine = {
          enable = _ true;
          command = mkIf ccstatuslineCheck (_ (getExe claudeCodeCfg.statusline.package));
        };
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (tokenCheck && dmsCheck) {
      services.ccdash.dms.enable = _ true;
    })
    # |----------------------------------------------------------------------| #
    (mkIf (tokenCheck && dmsCheck && niriCheck) {
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
