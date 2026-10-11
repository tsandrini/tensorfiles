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
{ localFlake, inputs }:
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
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.services.ccdash;
  claudeCodeCfg = config.tensorfiles.hm.programs.claude-code;
  _ = mkOverrideAtHmModuleLevel;

  dmsCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.dank-material-shell";
  niriCheck = isModuleLoadedAndEnabled config "tensorfiles.hm.programs.niri-flake";

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
        channel, so the web UI can reply to them and answer their permission
        prompts. Needs `programs.ccdash.channel.allow` on the NixOS host,
        otherwise Claude Code skips the channel.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 7837;
      description = ''
        Port of the read-only HTTP API and web UI, bound on all addresses.
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
        claudeCode.statusLine = {
          enable = _ true;
          command = mkIf ccstatuslineCheck (_ (getExe claudeCodeCfg.statusline.package));
        };
      };
    }
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
