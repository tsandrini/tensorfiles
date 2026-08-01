# --- flake-parts/modules/home-manager/programs/shells/atuin.nix
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
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkAfter
    mkOption
    mkEnableOption
    optional
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkImpermanenceEnableOption;

  cfg = config.tensorfiles.hm.programs.shells.atuin;

  impermanenceCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.system.impermanence") && cfg.impermanence.enable;
  impermanence = if impermanenceCheck then config.tensorfiles.hm.system.impermanence else { };

  _ = mkOverrideAtHmModuleLevel;
in
{
  options.tensorfiles.hm.programs.shells.atuin = {
    enable = mkEnableOption ''
      Enables a HomeManager module that sets up atuin, a sqlite backed
      shell history replacement with optional end to end encrypted sync.

      References
      - https://github.com/atuinsh/atuin
      - https://docs.atuin.sh
    '';

    impermanence = {
      enable = mkImpermanenceEnableOption;
    };

    takeUpArrow = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to let atuin bind the up-arrow key.

        When disabled (the default) atuin is launched via ctrl-r only and
        fish keeps its native `up-or-search` prefix search on up-arrow.
      '';
    };

    sync = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable end to end encrypted history sync.

          Note that registering/logging in (`atuin register`, `atuin login`)
          and the initial `atuin import auto` remain imperative one time
          steps, only the resulting key material lives in
          `$XDG_DATA_HOME/atuin/key`.
        '';
      };

      address = mkOption {
        type = types.str;
        default = "https://api.atuin.sh";
        description = ''
          Address of the atuin sync server to synchronize against.
        '';
      };

      frequency = mkOption {
        type = types.str;
        default = "5m";
        description = ''
          How often to automatically sync, given as a duration string.
          Use "0" to sync after every command.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.atuin = {
        enable = _ true;
        daemon.enable = _ true;

        # NOTE atuin rewrites config.toml after virtually every command, so the
        # generated file has to be allowed to clobber whatever it left behind.
        forceOverwriteSettings = _ true;

        flags = _ (optional (!cfg.takeUpArrow) "--disable-up-arrow");

        settings = {
          enter_accept = _ false; # NOTE: put back into fish after select
          inline_height = _ 25;
          style = _ "compact";
          filter_mode = _ "global"; # TODO: move to directory with more history
          secrets_filter = _ true;
          update_check = _ false;
          auto_sync = _ cfg.sync.enable;
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.sync.enable {
      programs.atuin.settings = {
        sync_address = _ cfg.sync.address;
        sync_frequency = _ cfg.sync.frequency;
        sync.records = _ true;
      };
    })
    # |----------------------------------------------------------------------| #
    (mkIf (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.fish") {
      # NOTE ctrl-r is contested by three binders that all land in
      # interactiveShellInit: home-manager's fzf integration (mkOrder 200), this
      # repo's fish module (mkBefore) and atuin (unordered, ie. 1000). Rather
      # than depend on that arithmetic, claim the key explicitly at the end.
      programs.fish.interactiveShellInit = mkAfter ''
        bind ctrl-r _atuin_search

        # NOTE atuin >= 18.15 unconditionally binds `?` to `atuin ai`, which
        # fires a request at the hosted AI service from an empty prompt. It is
        # gated by neither config.toml nor the --disable-* init flags, so the
        # binding has to be taken back here.
        bind '?' self-insert

        if bind -M insert >/dev/null 2>&1
          bind -M insert ctrl-r _atuin_search
          bind -M insert '?' self-insert
        end
      '';
    })
    # |----------------------------------------------------------------------| #
    (mkIf impermanenceCheck {
      # NOTE holds history.db, the sync key and the login session. Losing `key`
      # makes previously synced history undecryptable.
      home.persistence."${impermanence.persistentRoot}${config.home.homeDirectory}" = {
        directories = [ ".local/share/atuin" ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
