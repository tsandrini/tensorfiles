# --- flake-parts/modules/home-manager/programs/claude-code/default.nix
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
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    getExe
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.claude-code;
  _ = mkOverrideAtHmModuleLevel;

  llmPkgs = inputs.llm-agents.packages.${system};
in
{
  options.tensorfiles.hm.programs.claude-code = {
    enable = mkEnableOption ''
      Claude Code (Anthropic's CLI coding agent) with a declaratively
      managed global harness config — `~/.claude/CLAUDE.md` and
      `~/.claude/settings.json` — shared across hosts. MCP servers are
      inherited from `programs.mcp.servers` (mcp-servers-nix).
    '';

    extraPackages.enable =
      mkEnableOption ''
        companion Claude Code ecosystem CLIs (cc-switcher, ccusage,
        claudebox, sandbox-runtime, skills-installer, claude-plugins,
        auto-claude, agent-browser)
      ''
      // {
        default = true;
      };

    statusline = {
      enable =
        mkEnableOption ''
          ccstatusline — customizable statusline formatter for Claude Code
        ''
        // {
          default = true;
        };

      settingsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Captured ccstatusline configuration deployed declaratively to
          `~/.config/ccstatusline/settings.json`. When null, the config
          stays imperative — design it with the `ccstatusline` TUI, then
          capture the resulting file here to make it declarative (the TUI
          can no longer save once the file is a store symlink).
        '';
      };
    };

    mutableContextPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/tsandrini/ProjectBundle/tsandrini/tensorfiles/flake-parts/modules/home-manager/programs/claude-code/config/CLAUDE.md";
      description = ''
        Absolute path to `CLAUDE.md` inside a live checkout of this repo.
        When set, `~/.claude/CLAUDE.md` becomes an out-of-store symlink,
        so edits apply immediately without a rebuild. When null, the
        bundled `config/CLAUDE.md` is served from the nix store instead
        (edits then require a rebuild).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.claude-code = {
        enable = _ true;
        package = _ llmPkgs.claude-code;
        enableMcpIntegration = _ true;

        context = mkIf (cfg.mutableContextPath == null) (_ ./config/CLAUDE.md);

        rules = {
          harness-conventions = _ ./config/rules/harness-conventions.md;
        };

        skills = _ ./config/skills;

        settings = {
          env = {
            ANTHROPIC_AUTH_TOKEN = _ "";
            ANTHROPIC_BASE_URL = _ "";
            MAX_THINKING_TOKENS = _ "10000";
            CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = _ "75";
            CLAUDE_CODE_SUBAGENT_MODEL = _ "sonnet";
          };

          model = _ "claude-fable-5[1m]";
          effortLevel = _ "xhigh";
          promptSuggestionEnabled = _ false;
          awaySummaryEnabled = _ false;
          tui = _ "fullscreen";
          skipDangerousModePermissionPrompt = _ true;
          remoteControlAtStartup = _ true;
          skipAutoPermissionPrompt = _ true;

          # NOTE: enforces the git-readonly rule from CLAUDE.md; `git add` /
          # `git restore` intentionally absent — staging is granted per-repo
          permissions.deny = _ [
            "Bash(git commit:*)"
            "Bash(git push:*)"
            "Bash(git pull:*)"
            "Bash(git fetch:*)"
            "Bash(git checkout:*)"
            "Bash(git switch:*)"
            "Bash(git merge:*)"
            "Bash(git rebase:*)"
            "Bash(git reset:*)"
            "Bash(git stash:*)"
            "Bash(git tag:*)"
            "Bash(git cherry-pick:*)"
            "Bash(git revert:*)"
            "Bash(git clean:*)"
            "Bash(gh pr create:*)"
            "Bash(gh pr merge:*)"
            "Bash(gh pr close:*)"
            "Bash(gh repo delete:*)"
          ];
        };
      };

      # NOTE: upstream `context` sends non-`isPath` values to home.file
      # `.text`; mkOutOfStoreSymlink yields a derivation -> wire `.source`
      home.file.".claude/CLAUDE.md" = mkIf (cfg.mutableContextPath != null) {
        source = config.lib.file.mkOutOfStoreSymlink cfg.mutableContextPath;
      };

    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.extraPackages.enable {
      home.packages = [
        localFlake.packages.${system}.cc-switcher
        llmPkgs.auto-claude
        llmPkgs.claude-plugins
        llmPkgs.claudebox
        llmPkgs.skills-installer
        llmPkgs.sandbox-runtime
        llmPkgs.ccusage
        llmPkgs.agent-browser
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.statusline.enable {
      programs.claude-code.settings.statusLine = {
        type = _ "command";
        command = _ (getExe llmPkgs.ccstatusline);
        padding = _ 0;
      };

      # NOTE: ccstatusline doubles as its own TUI configurator
      home.packages = [ llmPkgs.ccstatusline ];

      xdg.configFile."ccstatusline/settings.json" = mkIf (cfg.statusline.settingsFile != null) {
        source = cfg.statusline.settingsFile;
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
