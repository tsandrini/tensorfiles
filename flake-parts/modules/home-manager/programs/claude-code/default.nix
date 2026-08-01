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
{
  localFlake,
  inputs,
  secretsPath,
}:
{
  config,
  lib,
  system,
  ...
}:
let
  inherit (builtins) pathExists;
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    mapAttrsToList
    types
    getExe
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.claude-code;
  _ = mkOverrideAtHmModuleLevel;

  llmPkgs = inputs.llm-agents.packages.${system};

  secretsCheck =
    (isModuleLoadedAndEnabled config "tensorfiles.hm.security.agenix") && cfg.secrets.enable;
in
{
  options.tensorfiles.hm.programs.claude-code = {
    enable = mkEnableOption ''
      Claude Code (Anthropic's CLI coding agent) with a declaratively
      managed global harness config — `~/.claude/CLAUDE.md` and
      `~/.claude/settings.json` — shared across hosts. MCP servers are
      inherited from `programs.mcp.servers` (mcp-servers-nix).
    '';

    secrets = {
      enable =
        mkEnableOption ''
          the per-workspace envfile secrets carrying read-only
          `CLAUDE_META_*` tokens, injected on every direnv evaluation via
          a direnvrc hook that resolves the nearest `.claude/meta-env`
          marker. Executed only when the `tensorfiles.hm.security.agenix`
          backend is loaded & enabled — a different secrets backend can
          supply the hook's envfiles instead.
        ''
        // {
          default = true;
        };

      envfileSecretsPaths = mkOption {
        type = types.attrsOf types.str;
        default = {
          meteopress = "common/claude-code-meteopress-meta-envfile";
          pesekmudra = "common/claude-code-pesekmudra-meta-envfile";
          tsandrini = "common/claude-code-tsandrini-meta-envfile";
        };
        description = ''
          Workspace name → secret path, relative to the secrets dir and
          without the `.age` suffix. Each workspace root's
          `.claude/meta-env` marker names its secret; the direnvrc hook
          resolves and loads the decrypted envfile.
        '';
      };
    };

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
            # MAX_THINKING_TOKENS = _ "10000";
            # CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = _ "75";
            # CLAUDE_CODE_SUBAGENT_MODEL = _ "sonnet";
          };

          model = _ "claude-opus-5";
          effortLevel = _ "xhigh";
          promptSuggestionEnabled = _ false;
          awaySummaryEnabled = _ false;
          tui = _ "fullscreen";
          skipDangerousModePermissionPrompt = _ true;
          remoteControlAtStartup = _ true;
          skipAutoPermissionPrompt = _ true;

          # NOTE: transcript/session-data retention (default 30d)
          cleanupPeriodDays = _ 365;

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
            # NOTE: secret hygiene — env files & decrypted agenix paths never
            # enter context (`.envrc` deliberately NOT matched)
            "Read(**/.env)"
            "Read(**/.env.*)"
            "Read(/run/agenix/**)"
            "Read(/run/user/*/agenix/**)"
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
    (mkIf secretsCheck {
      # NOTE: declarations activate once the .age files exist (`agenix -e`);
      # decrypted under $XDG_RUNTIME_DIR/agenix/
      age.secrets = mkMerge (
        mapAttrsToList (
          _ws: secretPath:
          mkIf (pathExists (secretsPath + "/${secretPath}.age")) {
            "${secretPath}".file = _ (secretsPath + "/${secretPath}.age");
          }
        ) cfg.secrets.envfileSecretsPaths
      );

      # NOTE: direnv layers don't nest — nested `direnv exec` would drop a
      # workspace-root env layer. This hook runs before EVERY .envrc
      # evaluation: it walks up to the nearest `.claude/meta-env` marker
      # (identity, versioned in the meta-root) and dotenv-loads the named
      # envfile (resolution, backend-specific to agenix here).
      programs.direnv.stdlib = ''
        _claude_meta_env_load() {
          local dir="$PWD" secret_name envfile
          while [ -n "$dir" ]; do
            if [ -r "$dir/.claude/meta-env" ]; then
              secret_name="$(<"$dir/.claude/meta-env")"
              envfile="''${XDG_RUNTIME_DIR:-/run/user/$UID}/agenix/$secret_name"
              if [ -n "$secret_name" ] && [ -r "$envfile" ]; then
                dotenv "$envfile"
              fi
              break
            fi
            dir="''${dir%/*}"
          done
        }
        _claude_meta_env_load
      '';
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
