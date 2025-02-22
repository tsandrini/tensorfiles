# --- flake-parts/modules/nixvim/plugins/lsp/fidget.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
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
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.lsp.fidget;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.fidget = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.fidget = {
        enable = _ true;
        settings = {
          logger = {
            level = _ "warn"; # “off”, “error”, “warn”, “info”, “debug”, “trace”
            floatPrecision = _ 1.0e-2; # Limit the number of decimals displayed for floats
          };
          progress = {
            pollRate = _ 0; # How and when to poll for progress messages
            # suppressOnInsert = true; # Suppress new messages while in insert mode
            ignoreDoneAlready = _ false; # Ignore new tasks that are already complete
            ignoreEmptyMessage = _ false; # Ignore new tasks that don't contain a message
            clearOnDetach =
              # Clear notification group when LSP server detaches
              ''
                function(client_id)
                  local client = vim.lsp.get_client_by_id(client_id)
                  return client and client.name or nil
                end
              '';
            notificationGroup =
              # How to get a progress message's notification group key
              ''
                function(msg) return msg.lsp_client.name end
              '';
            ignore = [ ]; # List of LSP servers to ignore
            lsp = {
              progressRingbufSize = _ 0; # Configure the nvim's LSP progress ring buffer size
            };
            display = {
              renderLimit = _ 16; # How many LSP messages to show at once
              doneTtl = _ 3; # How long a message should persist after completion
              doneIcon = _ "✔"; # Icon shown when all LSP progress tasks are complete
              doneStyle = _ "Constant"; # Highlight group for completed LSP tasks
              progressTtl = lib.nixvim.mkRaw "math.huge"; # How long a message should persist when in progress
              progressIcon = {
                pattern = _ "dots";
                period = _ 1;
              }; # Icon shown when LSP progress tasks are in progress
              progressStyle = _ "WarningMsg"; # Highlight group for in-progress LSP tasks
              groupStyle = _ "Title"; # Highlight group for group name (LSP server name)
              iconStyle = _ "Question"; # Highlight group for group icons
              priority = _ 30; # Ordering priority for LSP notification group
              skipHistory = _ true; # Whether progress notifications should be omitted from history
              formatMessage = ''
                require ("fidget.progress.display").default_format_message
              ''; # How to format a progress message
              formatAnnote = ''
                function (msg) return msg.title end
              ''; # How to format a progress annotation
              formatGroupName = ''
                function (group) return tostring (group) end
              ''; # How to format a progress notification group's name
              overrides = {
                rust_analyzer = {
                  name = _ "rust-analyzer";
                };
              }; # Override options from the default notification config
            };
          };
          notification = {
            pollRate = _ 10; # How frequently to update and render notifications
            filter = _ "info"; # “off”, “error”, “warn”, “info”, “debug”, “trace”
            historySize = _ 128; # Number of removed messages to retain in history
            overrideVimNotify = _ true;
            redirect = lib.nixvim.mkRaw ''
              function(msg, level, opts)
                if opts and opts.on_open then
                  return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
                end
              end
            '';
            configs = {
              default = lib.nixvim.mkRaw "require('fidget.notification').default_config";
            };

            window = {
              normalHl = _ "Comment";
              winblend = _ 0;
              border = _ "none"; # none, single, double, rounded, solid, shadow
              zindex = _ 45;
              maxWidth = _ 0;
              maxHeight = _ 0;
              xPadding = _ 1;
              yPadding = _ 0;
              align = _ "bottom";
              relative = _ "editor";
            };
            view = {
              stackUpwards = _ true; # Display notification items from bottom to top
              iconSeparator = _ " "; # Separator between group name and icon
              groupSeparator = _ "---"; # Separator between notification groups
              groupSeparatorHl =
                # Highlight group used for group separator
                "Comment";
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
